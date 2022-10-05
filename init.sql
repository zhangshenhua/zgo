-- 在sqlite3 v3.39.4中执行本文件

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

insert into sqlite_sequence VALUES ('ZI', 0); 
update sqlite_sequence set seq = 0 where name = 'ZI';

-- 最后落的子a
DROP VIEW IF EXISTS VIEW_LAST_ZI;
CREATE VIEW VIEW_LAST_ZI AS
    select * from ZI ORDER by id DESC LIMIT 1
    ;


-- a以及与a相邻的子
drop view if EXISTS VIEW_LAST_ADJOINING_ZI;
CREATE VIEW VIEW_LAST_ADJOINING_ZI AS
    select ZI.*
    from ZI, VIEW_LAST_ZI as LAST_ZI
    where   (ZI.x, ZI.y) in (
                                (LAST_ZI.x, LAST_ZI.y),
                                (LAST_ZI.x+1, LAST_ZI.y),
                                (LAST_ZI.x-1, LAST_ZI.y),
                                (LAST_ZI.x, LAST_ZI.y+1),
                                (LAST_ZI.x, LAST_ZI.y-1)
                            )
    ;

-- 与a利益相关的块。
drop view if EXISTS VIEW_LAST_RELATED_BLOCKS;
CREATE VIEW VIEW_LAST_RELATED_BLOCKS AS
    select ZI.bid, ZI.uid
    from ZI, VIEW_LAST_ADJOINING_ZI as ADJ
    where  ZI.bid = ADJ.bid
    group by ZI.bid
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
                                and ZI.y = T1.y)
        GROUP BY T1.bid
    ;

 SELECT * FROM VIEW_RELATED_BLOCKS_QISHU;


-- 落子之后发生的事情
drop TRIGGER if EXISTS zi_insert_clear_trigger;
CREATE TRIGGER zi_insert_clear_trigger
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

    
    -- 2.提走与a相邻的非己方的无气的块。(气是空位的集合)
    -- B <- {b| b in B_enemy, qi(b)={}}
    -- qi(b) = (  {(x-1,y)|(x,y) in b} 
    --         U {(x+1,y)|(x,y) in b} 
    --         U {(x,-y)|(x,y) in b}
    --         U {(x,+y)|(x,y) in b} ) - ZI
    DELETE FROM ZI
    where bid in ( -- 无气的敌块
        SELECT  T1.bid
        FROM    VIEW_RELATED_BLOCKS_QISHU T1,
                VIEW_LAST_ZI T2
        WHERE   T1.uid <> T2.uid    -- 非己方块
            and T1.QiShu = 0 
    )
    ;
    -- 3.提走与a相邻的无气的块。(气是空位的集合)
    -- B <- {b| b in B_own, qi(b)={}}
    -- qi(b) = (  {(x-1,y)|(x,y) in b} 
    --         U {(x+1,y)|(x,y) in b} 
    --         U {(x,-y)|(x,y) in b}
    --         U {(x,+y)|(x,y) in b} ) - ZI 
    DELETE FROM ZI
    where bid in ( -- 无气的块
        SELECT  T1.bid
        FROM    VIEW_RELATED_BLOCKS_QISHU T1
        WHERE   T1.QiShu = 0 
    )
    ;    
END;

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




