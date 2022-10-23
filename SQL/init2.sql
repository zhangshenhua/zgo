-- 在sqlite3 v3.39.4中执行本文件




DROP VIEW IF EXISTS NOW;
CREATE VIEW NOW AS
    select datetime('now','localtime') as value
;
SELECT * FROM NOW;



-- 记录每个块的所属以及有多少气
DROP TABLE IF EXISTS BLOCK;
CREATE TABLE BLOCK (
    id  INTEGER PRIMARY KEY AUTOINCREMENT,  
    uid UNSIGNED INT NOT NULL,
    qi UNSIGNED INT
);
CREATE INDEX index_bid ON BLOCK (id);
CREATE INDEX index_uid ON BLOCK (uid);
insert into sqlite_sequence VALUES ('BLOCK', 0); 
update sqlite_sequence set seq = 0 where name = 'BLOCK';

-- 记录每个坐标所对应的块
drop TABLE IF EXISTS ZI;
CREATE table ZI(
    x INT2 check(x >= -10000 and x <= 10000),
    y INT2 check(y >= -10000 and y <= 10000),
    bid INTEGER NOT NULL,
    PRIMARY KEY (x, y),
    FOREIGN KEY(bid) REFERENCES BLOCK(id)
);
CREATE unique INDEX index_zi_x_y on ZI (x,y);
CREATE INDEX index_zi_x on ZI (x);
CREATE INDEX index_zi_y on ZI (y);
CREATE INDEX index_bid  on ZI (bid);







-- 存放系统参数用的表
drop TABLE IF EXISTS ENV;
create table ENV(
    name    TEXT    PRIMARY KEY,
    value   TEXT
);
INSERT INTO ENV VALUES('system_start_time', (SELECT value FROM NOW));
INSERT INTO ENV(name) VALUES('last_go_time');
INSERT INTO ENV(name) VALUES('last_x');
INSERT INTO ENV(name) VALUES('last_y');
INSERT INTO ENV(name) VALUES('last_uid');
INSERT INTO ENV(name) VALUES('trigger_ok');

-- 存放运行时变量
drop TABLE IF EXISTS VAR;
create table VAR(
    last_zid   INTEGER
);
insert INTO VAR(last_zid) VALUES (NULL);


-- 最后落的子a
DROP VIEW IF EXISTS VIEW_LAST_ZI;
CREATE VIEW VIEW_LAST_ZI AS
    select uid, x, y, bid 
    from ZI ORDER by rowid DESC LIMIT 1
    ;

-- SELECT * from view_last_zi;

-- a以及与a相邻的子
drop view if EXISTS VIEW_LAST_ADJOINING_ZI;
CREATE VIEW VIEW_LAST_ADJOINING_ZI AS
    with N5(x, y) as ( 
                SELECT x, y   FROM VIEW_LAST_ZI
                UNION
                SELECT x, y-1 FROM VIEW_LAST_ZI 
                UNION
                SELECT x, y+1 FROM VIEW_LAST_ZI
                UNION
                SELECT x-1, y FROM VIEW_LAST_ZI
                UNION
                SELECT x+1, y FROM VIEW_LAST_ZI)
    SELECT N5.x, N5.y, ZI.bid as bid 
    FROM N5 INNER JOIN ZI ON N5.x = ZI.x AND N5.y = ZI.y
    ;

-- explain 
-- select * from VIEW_LAST_ADJOINING_ZI;


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
    select bid
    from VIEW_LAST_ADJOINING_ZI
    GROUP BY bid
    ;
-- select * from VIEW_LAST_RELATED_BLOCKS;

-- 与a利益相关的己方的块。
drop view if EXISTS VIEW_LAST_RELATED_OWN_BLOCKS;
CREATE VIEW VIEW_LAST_RELATED_OWN_BLOCKS AS
    select ADJ.bid as bid
    from  VIEW_LAST_RELATED_BLOCKS ADJ INNER JOIN BLOCK B
    ON ADJ.bid = B.id AND B.uid = (SELECT cast(value as INT) FROM ENV where name = 'last_uid')
    ;
-- select * from VIEW_LAST_RELATED_OWN_BLOCKS;

-- 与a利益相关的非己方的块
drop view if EXISTS VIEV_LAST_RELATED_ENEMY_BLOCKS;
CREATE VIEW VIEV_LAST_RELATED_ENEMY_BLOCKS AS
    SELECT bid FROM VIEW_LAST_RELATED_BLOCKS
    EXCEPT
    SELECT bid FROM VIEW_LAST_RELATED_OWN_BLOCKS
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
                                and ZI.y = T1.y)
        GROUP BY T1.bid
    ;

SELECT * FROM VIEW_RELATED_BLOCKS_QISHU;


-- VIEW_ZI是与"后端程序"的接口。"后端程序":
-- insert into VIEW_ZI(uid, x, y) values (<uid>, <x>, <y>); -- 块信息由数据库通过触发器来维护
-- 或者select * from VIEW_ZI;                               -- 布局信息由数据库负责给出
DROP VIEW IF EXISTS VIEW_ZI;
CREATE VIEW VIEW_ZI AS
    SELECT  B.uid as uid
            , B.id as bid
            , ZI.x as x
            , ZI.y as y
    FROM    BLOCK B INNER join ZI ON B.id = ZI.bid
    ;
-- select * from  VIEW_ZI;

SELECT CURRENT_TIMESTAMP

-- 落子触发器 trigger_instead_of_insert_into_VIEW_ZI;
DROP TRIGGER IF EXISTS trigger_instead_of_insert_into_VIEW_ZI;
CREATE TRIGGER trigger_instead_of_insert_into_VIEW_ZI
INSTEAD OF INSERT ON VIEW_ZI
BEGIN
    UPDATE ENV SET value = '0'   WHERE name = 'trigger_ok';
    UPDATE ENV SET value = CURRENT_TIMESTAMP  WHERE name = 'last_go_time';
    UPDATE ENV SET value = NEW.x   WHERE name = 'last_x';
    UPDATE ENV SET value = NEW.y   WHERE name = 'last_y';
    UPDATE ENV SET value = NEW.uid WHERE name = 'last_uid';
    -- 在B中注册新块
    INSERT INTO BLOCK(uid, qi)
    VALUES (NEW.uid, 
            4 - (   SELECT  count(*)
                    FROM    ZI
                    WHERE   (x = NEW.x+1 and y = NEW.y  )
                    OR      (x = NEW.x-1 and y = NEW.y  )
                    OR      (x = NEW.x   and y = NEW.y+1)
                    OR      (x = NEW.x   and y = NEW.y-1)
                    ));

    -- 在ZI中注册新子
    INSERT INTO ZI(x, y, bid)
    SELECT NEW.x, NEW.y, (SELECT seq FROM sqlite_sequence WHERE name = 'BLOCK');

    -- 合并相邻的己方块
    UPDATE ZI 
    SET bid = (select min(OWN.bid) from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
    where 
        ZI.bid in (select OWN.bid from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
    ;
    -- 更新
    -- 写到这里，遇到关联子计气问题。只好先放放了。


    UPDATE ENV SET value = '1'   WHERE name = 'trigger_ok';
END;


-- VIEW_B_ADJ 
SELECT  from zi;

-- -- 落子之后发生的事情。
-- drop TRIGGER if EXISTS after_zi_insert_trigger;
-- CREATE TRIGGER after_zi_insert_trigger
-- AFTER INSERT
-- ON ZI
-- FOR EACH ROW
-- BEGIN
--     -- 1.将a并入邻近的己方块。
--     UPDATE ZI 
--     SET bid = (select min(OWN.bid) from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
--     where 
--         ZI.bid in (select OWN.bid from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
--     ;    

--     -- 更新last_go_time变量
--     UPDATE ENV SET value = (select value FROM NOW) WHERE name = 'last_go_time';
--     UPDATE VAR SET last_zid = (select id FROM VIEW_LAST_ZI);
-- END;
-- -- SELECT * from ENV;

-- -- 落子之后发生的事情。为此系统的核心装置。
-- drop TRIGGER if EXISTS zi_insert_clear_trigger;
-- CREATE TRIGGER zi_insert_clear_trigger
-- AFTER UPDATE
-- OF last_zid ON VAR
-- FOR EACH ROW
-- WHEN 
--     (SELECT value FROM VIEW_LAST_ZI_QISHU) = 0 OR
--     EXISTS(SELECT * FROM VIEV_LAST_RELATED_ENEMY_BLOCKS)
-- BEGIN
--     -- 2.提走与a相邻的非己方的无气的块。(气是空位的集合)
--     -- B <- {b| b in B_enemy, qi(b)={}}
--     -- qi(b) = (  {(x-1,y)|(x,y) in b} 
--     --         U {(x+1,y)|(x,y) in b} 
--     --         U {(x,-y)|(x,y) in b}
--     --         U {(x,+y)|(x,y) in b} ) - ZI
--     DELETE FROM ZI
--     where bid in ( -- 无气的敌块
--         SELECT  T1.bid
--         FROM    VIEW_RELATED_BLOCKS_QISHU T1,
--                 VIEW_LAST_ZI T2
--         WHERE   T1.uid <> T2.uid    -- 非己方块
--             and T1.QiShu = 0 
--     )
--     ;
--     -- 3.提走与a相邻的无气的块。(气是空位的集合)
--     -- B <- {b| b in B_own, qi(b)={}}
--     -- qi(b) = (  {(x-1,y)|(x,y) in b} 
--     --         U {(x+1,y)|(x,y) in b} 
--     --         U {(x,-y)|(x,y) in b}
--     --         U {(x,+y)|(x,y) in b} ) - ZI 
--     DELETE FROM ZI
--     where bid in ( -- 无气的块
--         SELECT  T1.bid
--         FROM    VIEW_RELATED_BLOCKS_QISHU T1
--         WHERE   T1.QiShu = 0 
--     )
--     ;    

    
-- END;


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
DELETE FROM ZI;
DELETE FROM BLOCK;
update sqlite_sequence set seq = 0 where name = 'BLOCK';
insert INTO VIEW_ZI (x, y, uid) SELECT 1, 0,    0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 0, 1,    0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT -1, 0,   0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 0, -1,   0 ;

insert INTO VIEW_ZI (x, y, uid) SELECT  0,  2,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT  0, -2,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT -2,  0,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT  2,  0,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT -1,  1,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT -1, -1,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT  1,  1,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT  1, -1,  1 ;
insert INTO VIEW_ZI (x, y, uid) SELECT  0, 0,   2 ;

insert INTO VIEW_ZI (x, y, uid) SELECT 100, 2,  0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 100, 3,  0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 100, 4,  1 ;

insert INTO VIEW_ZI (x, y, uid) SELECT 1, 0,    0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 0, 1,    0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT -1, 0,   0 ;
insert INTO VIEW_ZI (x, y, uid) SELECT 0, -1,   0 ;
SELECT * FROM ENV;
SELECT * from ZI;
SELECT * from BLOCK;


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
INSERT INTO ZI(x, y, bid, uid)
SELECT 
        POS.x, 
        POS.y,
        (SELECT seq+1 FROM sqlite_sequence where name = 'ZI'),
        4294967040
FROM (
    WITH RECURSIVE
        X(v) as (
            SELECT * from generate_series(-1,19,1)
        ),
        Y(v) as (
            SELECT * from generate_series(-1,19,1)
        )   
        SELECT  X.v as x, Y.v as y
        FROM  X, Y      
        where X.v = -1 or X.v = 19 or Y.v = -1 or Y.v = 19
    ) POS
    ;

SELECT * FROM ENV;

-- 为经典围棋保留的区域
DROP VIEW IF EXISTS VIEW_STD_AREA;
CREATE VIEW VIEW_STD_AREA AS
    WITH RECURSIVE
        X(v) as (
            SELECT * from generate_series(0,18,1)
        ),
        Y(v) as (
            SELECT * from generate_series(0,18,1)
        )   
        SELECT  X.v as x, Y.v as y
        FROM  X, Y     
    ;
-- select * from VIEW_STD_AREA;


DELETE FROM ZI
WHERE (ZI.x, ZI.y) in (
    SELECT * FROM VIEW_STD_AREA
    );