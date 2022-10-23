-- 在sqlite3 v3.39.4中执行本文件
-- 现实化的服务器地址是 http://124.221.142.162:8081/
-- init3.sql 希望实现一个略微高效的 VIEW_NEED_CLEAR 供触发器的when使用。
-- init3.1.sql 希望将 init3.sql 中的新思想更彻底的贯彻。


DROP VIEW IF EXISTS NOW;
CREATE VIEW NOW AS
    select datetime('now','localtime') as value
;
SELECT * FROM NOW;


drop TABLE IF EXISTS ZI;
create table ZI(
    id INTEGER PRIMARY KEY autoincrement,
    x INT2 check(x >= -10000 and x <= 10000),
    y INT2 check(y >= -10000 and y <= 10000),
    bid UNSIGNED INT NOT NULL,
    uid UNSIGNED INT NOT NULL ,
    Unique (x, y)
);
create unique INDEX index_zi_x_y on ZI (x,y);
create INDEX index_zi_x on ZI (x);
create INDEX index_zi_y on ZI (y);
CREATE INDEX index_bid ON ZI (bid);
CREATE INDEX index_uid ON ZI (uid);
insert into sqlite_sequence VALUES ('ZI', 0); 
update sqlite_sequence set seq = 0 where name = 'ZI';



-- 存放系统参数用的表
drop TABLE IF EXISTS ENV;
create table ENV(
    name    TEXT    PRIMARY KEY,
    value   TEXT
);
INSERT INTO ENV VALUES('system_start_time', (SELECT value FROM NOW));
INSERT INTO ENV(name) VALUES('last_go_time');
INSERT INTO ENV(name) VALUES('last_zid');


-- 存放运行时变量
drop TABLE IF EXISTS VAR;
create table VAR(
    last_zid   INTEGER
);
insert INTO VAR(last_zid) VALUES (NULL);


-- 最后落的子a
DROP VIEW IF EXISTS VIEW_LAST_ZI;
CREATE VIEW VIEW_LAST_ZI AS
    select * from ZI ORDER by id DESC LIMIT 1
    ;


-- a以及与a相邻的子
drop view if EXISTS VIEW_LAST_ADJOINING_ZI;
CREATE VIEW VIEW_LAST_ADJOINING_ZI AS
    with N5(x, y) as ( 
                SELECT x, y FROM VIEW_LAST_ZI
                UNION
                SELECT x, y-1 FROM VIEW_LAST_ZI 
                UNION
                SELECT x, y+1 FROM VIEW_LAST_ZI
                UNION
                SELECT x-1, y FROM VIEW_LAST_ZI
                UNION
                SELECT x+1, y FROM VIEW_LAST_ZI)
    select ZI.* 
    from N5 INNER JOIN ZI ON ZI.x = N5.x and ZI.y = N5.y
    ;

explain 
select * from VIEW_LAST_ADJOINING_ZI;


-- a有几口气？
DROP VIEW IF EXISTS VIEW_LAST_ZI_QISHU;
CREATE VIEW VIEW_LAST_ZI_QISHU AS
    WITH
        NEIGHBORS_A(x, y) as (
            SELECT x, y-1 FROM VIEW_LAST_ZI 
            UNION
            SELECT x, y+1 FROM VIEW_LAST_ZI
            UNION
            SELECT x-1, y FROM VIEW_LAST_ZI
            UNION
            SELECT x+1, y FROM VIEW_LAST_ZI
        )
        SELECT 4 - (
            SELECT  count(*)
            FROM    ZI, NEIGHBORS_A A
            WHERE   ZI.x = A.x and ZI.y = A.y
            ) as value
    ;

-- select * from VIEW_LAST_ZI_QISHU;

-- 与a利益相关的块。
drop view if EXISTS VIEW_LAST_RELATED_BLOCKS;
CREATE VIEW VIEW_LAST_RELATED_BLOCKS AS
    select bid, uid
    from VIEW_LAST_ADJOINING_ZI as ADJ
    GROUP BY bid
    ;

-- 与a利益相关的己方的块。
drop view if EXISTS VIEW_LAST_RELATED_OWN_BLOCKS;
CREATE VIEW VIEW_LAST_RELATED_OWN_BLOCKS AS
    select ADJ.*
    from  VIEW_LAST_RELATED_BLOCKS as ADJ, VIEW_LAST_ZI as A
    where  ADJ.uid = A.uid
    ;

-- 与a利益相关的非己方的块
drop view if EXISTS VIEV_LAST_RELATED_ENEMY_BLOCKS;
CREATE VIEW VIEV_LAST_RELATED_ENEMY_BLOCKS AS
    select ADJ.bid
    from  VIEW_LAST_RELATED_BLOCKS as ADJ, VIEW_LAST_ZI as A
    where  ADJ.uid <> A.uid
    ;

-- 与a利益相关的块的各块的气数
DROP VIEW IF EXISTS VIEW_RELATED_BLOCKS_QISHU;
CREATE VIEW VIEW_RELATED_BLOCKS_QISHU AS
    WITH
        XY_IN_B(uid, bid, x, y) as ( -- 相关敌块中所有子的坐标
            select ZI.uid, ZI.bid, ZI.x, ZI.y 
            FROM ZI JOIN VIEW_LAST_RELATED_BLOCKS as B ON ZI.bid = B.bid
        ),
        NEIGHBORS_B(uid, bid, x, y) as (
            SELECT uid, bid, x, y-1 FROM XY_IN_B 
            UNION
            SELECT uid, bid, x, y+1 FROM XY_IN_B
            UNION
            SELECT uid, bid, x-1, y FROM XY_IN_B
            UNION
            SELECT uid, bid, x+1, y FROM XY_IN_B
        )
        SELECT  -- R.uid, 
                T1.uid, T1.bid, count(ZI.id) as QiShu
        FROM    
            -- VIEW_LAST_RELATED_BLOCKS L LEFT JOIN 
            NEIGHBORS_B T1 
            LEFT JOIN ZI
            ON T1.bid = ZI.bid 
                and NOT EXISTS (select 1 
                                from ZI 
                                where ZI.x = T1.x
                                and ZI.y = T1.y
                                LIMIT 1)
        GROUP BY T1.bid
    ;

SELECT * FROM VIEW_RELATED_BLOCKS_QISHU;


-- 落子之后发生的事情。
drop TRIGGER if EXISTS after_zi_insert_trigger;
CREATE TRIGGER after_zi_insert_trigger
AFTER INSERT
ON ZI
FOR EACH ROW
BEGIN
    -- 1.将a并入邻近的己方块。
    UPDATE ZI 
    SET bid = (select min(OWN.bid) from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
    where 
        ZI.bid in (select OWN.bid from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
    ;    

    -- 更新last_go_time变量
    UPDATE ENV SET value = (select value FROM NOW) WHERE name = 'last_go_time';
    UPDATE VAR SET last_zid = (select id FROM VIEW_LAST_ZI);
END;
-- SELECT * from ENV;


-- 列出所有需要结算的块
DROP VIEW IF EXISTS VIEW_NEED_CLEAR_BLOCKS;
CREATE VIEW VIEW_NEED_CLEAR_BLOCKS AS
    -- 与a相关的块中只要存在无气的块就需要结算
    -- 有气的块的数量要与块的数量相等，否则就要结算。
    -- 一个块有气是指其中任意一子有气。
    -- 那么没气的块就是:
    SELECT  B.bid as bid
    FROM    VIEW_LAST_RELATED_BLOCKS B
    WHERE   NOT EXISTS( -- bid所指的块无气
        -- bid有气
        WITH 
        Q(x,y) as (
            SELECT x+1, y FROM ZI WHERE ZI.bid = B.bid
            union
            SELECT x-1, y FROM ZI WHERE ZI.bid = B.bid
            union
            SELECT x, y+1 FROM ZI WHERE ZI.bid = B.bid
            union
            SELECT x, y-1 FROM ZI WHERE ZI.bid = B.bid
            EXCEPT
            SELECT x, y FROM ZI
        )
        SELECT * from Q
        limit 1
    )
;


-- 是否需要结算
DROP VIEW IF EXISTS VIEW_NEED_CLEAR;
CREATE VIEW VIEW_NEED_CLEAR AS
    -- 与a相关的块中只要存在无气的块就需要结算
    -- 有气的块的数量要与块的数量相等，否则就要结算。
    -- 一个块有气是指其中仍一子有气。
    SELECT  exists( -- 存在没气的块
                SELECT  bid FROM VIEW_NEED_CLEAR_BLOCKS
            ) as need
;
-- select * from VIEW_NEED_CLEAR;


-- 落子之后发生的事情。为此系统的核心装置。
drop TRIGGER if EXISTS zi_insert_clear_trigger;
CREATE TRIGGER zi_insert_clear_trigger
AFTER UPDATE
OF last_zid ON VAR
FOR EACH ROW
WHEN 
    (SELECT need from VIEW_NEED_CLEAR) = 1
BEGIN
    -- 2.提走与a相邻的非己方的无气的块。(气是空位的集合)
    -- B <- {b| b in B_enemy, qi(b)={}}
    -- qi(b) = (  {(x-1,y)|(x,y) in b} 
    --         U {(x+1,y)|(x,y) in b} 
    --         U {(x,-y)|(x,y) in b}
    --         U {(x,+y)|(x,y) in b} ) - ZI
    DELETE FROM ZI
    where bid in ( -- 无气的敌块
        SELECT  B.bid
        FROM    VIEW_NEED_CLEAR_BLOCKS B INNER JOIN ZI ON B.bid = ZI.bid
                INNER JOIN VIEW_LAST_ZI a ON a.uid <> ZI.uid
    )
    ;
    -- 3.提走与a相邻的无气的块。(气是空位的集合)
    -- B <- {b| b in B_own, qi(b)={}}
    -- qi(b) = (  {(x-1,y)|(x,y) in b} 
    --         U {(x+1,y)|(x,y) in b} 
    --         U {(x,-y)|(x,y) in b}
    --         U {(x,+y)|(x,y) in b} ) - ZI 
    DELETE FROM ZI
    where bid in ( -- 无气的己方块
        SELECT  B.bid
        FROM    VIEW_NEED_CLEAR_BLOCKS B INNER JOIN ZI ON B.bid = ZI.bid
                INNER JOIN VIEW_LAST_ZI a ON a.uid = ZI.uid
    )
    ;  
END;


-- 最后落子时间
DROP VIEW IF EXISTS VIEW_LAST_GO_TIME;
CREATE VIEW VIEW_LAST_GO_TIME AS
    SELECT value FROM ENV WHERE name = 'last_go_time'
;
-- select * from VIEW_LAST_GO_TIME

-- 距离最后落子过去几分钟
DROP VIEW IF EXISTS VIEW_MINS_AGO;
CREATE VIEW VIEW_MINS_AGO AS
    SELECT  (strftime('%s', datetime(NOW.value)) 
            - strftime('%s', datetime(T.value)))/60 as value
    FROM NOW, VIEW_LAST_GO_TIME T
;
-- SELECT * FROM VIEW_MINS_AGO;

-- tests
-- insert INTO ZI (x, y, bid, uid) SELECT 1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 0, 1, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT -1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 0, -1, seq+1, 0 from sqlite_sequence where  name='ZI';

-- insert INTO ZI (x, y, bid, uid) SELECT  0,  2, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  0, -2, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT -2,  0, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  2,  0, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT -1,  1, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT -1, -1, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  1,  1, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  1, -1, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  0, 0, seq+1, 2 from sqlite_sequence where  name='ZI';

-- insert INTO ZI (x, y, bid, uid) SELECT 100, 2, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 100, 3, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 100, 4, seq+1, 1 from sqlite_sequence where  name='ZI';

-- insert INTO ZI (x, y, bid, uid) SELECT 1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 0, 1, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT -1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT 0, -1, seq+1, 0 from sqlite_sequence where  name='ZI';
-- SELECT * from ZI;
-- DELETE FROM ZI;
-- update sqlite_sequence set seq = 0 where name = 'ZI';

-- -- tests DaJie
-- insert INTO ZI (x, y, bid, uid) SELECT  9,  8, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  8,  9, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  9,  10, seq+1, 1 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  8, seq+1, 2 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  11,  9, seq+1, 2 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  10, seq+1, 2 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  9,  9, seq+1, 2 from sqlite_sequence where  name='ZI';
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  9, seq+1, 1 from sqlite_sequence where  name='ZI';
-- select * from sqlite_sequence;
-- SELECT * from ZI;
-- DELETE FROM ZI;
-- update sqlite_sequence set seq = 0 where name = 'ZI';


-- make border
-- INSERT INTO ZI(x, y, bid, uid)
-- SELECT 
--         POS.x, 
--         POS.y,
--         (SELECT seq+1 FROM sqlite_sequence where name = 'ZI'),
--         4294967040
-- FROM (
--     WITH RECURSIVE
--         X(v) as (
--             SELECT * from generate_series(-1,19,1)
--         ),
--         Y(v) as (
--             SELECT * from generate_series(-1,19,1)
--         )   
--         SELECT  X.v as x, Y.v as y
--         FROM  X, Y      
--         where X.v = -1 or X.v = 19 or Y.v = -1 or Y.v = 19
--     ) POS
--     ;

-- SELECT * FROM ENV;

-- 为经典围棋保留的区域
-- DROP VIEW IF EXISTS VIEW_STD_AREA;
-- CREATE VIEW VIEW_STD_AREA AS
--     WITH RECURSIVE
--         X(v) as (
--             SELECT * from generate_series(0,18,1)
--         ),
--         Y(v) as (
--             SELECT * from generate_series(0,18,1)
--         )   
--         SELECT  X.v as x, Y.v as y
--         FROM  X, Y     
--     ;
-- -- select * from VIEW_STD_AREA;


-- DELETE FROM ZI
-- WHERE (ZI.x, ZI.y) in (
--     SELECT * FROM VIEW_STD_AREA
--     );
