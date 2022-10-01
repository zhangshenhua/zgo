-- 在sqlite3中执行本文件

drop TABLE IF EXISTS ZI;

create table ZI(
    rowid INTEGER PRIMARY KEY autoincrement,
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
    select * from ZI ORDER by rowid DESC LIMIT 1
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
    where bid in (
            SELECT B.bid
            FROM VIEV_LAST_RELATED_ENEMY_BLOCKS as B 
            WHERE NOT EXISTS (
                WITH RECURSIVE
                    XY_IN_B(x,y) as (
                        select ZI.x, ZI.y 
                        FROM ZI JOIN VIEV_LAST_RELATED_ENEMY_BLOCKS as B ON ZI.bid = B.bid
                    ),
                    NEIGHBORS_B(x,y) as (
                        SELECT x, y-1 FROM XY_IN_B 
                        UNION
                        SELECT x, y+1 FROM XY_IN_B
                        UNION
                        SELECT x-1, y FROM XY_IN_B
                        UNION
                        SELECT x+1, y FROM XY_IN_B
                    ),
                    QI(x,y) as (
                        SELECT N.x, N.y
                        FROM ZI, NEIGHBORS_B as N
                        WHERE NOT EXISTS (select 1 
                                          from ZI 
                                          where ZI.x = N.x
                                            and ZI.y = N.y)
                    )
                select 1 from QI
            )
        )
    ;
    -- 3.提走与a相邻的己方的无气的块。(气是空位的集合)
    -- B <- {b| b in B_own, qi(b)={}}
    -- qi(b) = (  {(x-1,y)|(x,y) in b} 
    --         U {(x+1,y)|(x,y) in b} 
    --         U {(x,-y)|(x,y) in b}
    --         U {(x,+y)|(x,y) in b} ) - ZI
    DELETE FROM ZI
    where bid in (
            SELECT B.bid
            FROM VIEW_LAST_RELATED_OWN_BLOCKS as B 
            WHERE NOT EXISTS (
                WITH RECURSIVE
                    XY_IN_B(x,y) as (
                        select ZI.x, ZI.y 
                        FROM ZI JOIN VIEW_LAST_RELATED_OWN_BLOCKS as B ON ZI.bid = B.bid
                    ),
                    NEIGHBORS_B(x,y) as (
                        SELECT x, y-1 FROM XY_IN_B 
                        UNION
                        SELECT x, y+1 FROM XY_IN_B
                        UNION
                        SELECT x-1, y FROM XY_IN_B
                        UNION
                        SELECT x+1, y FROM XY_IN_B
                    ),
                    QI(x,y) as (
                        SELECT N.x, N.y
                        FROM ZI, NEIGHBORS_B as N
                        WHERE NOT EXISTS (select 1 
                                          from ZI 
                                          where ZI.x = N.x
                                            and ZI.y = N.y)
                    )
                select 1 from QI
            )
        )
    ;
END;
  
-- tests
insert INTO ZI (x, y, bid, uid) SELECT 1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 0, 1, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT -1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 0, -1, seq+1, 0 from sqlite_sequence where  name='ZI';

insert INTO ZI (x, y, bid, uid) SELECT  0,  2, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT  0, -2, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT -2,  0, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT  2,  0, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT -1,  1, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT -1, -1, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT  1,  1, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT  1, -1, seq+1, 1 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT  0, 0, seq+1, 2 from sqlite_sequence where  name='ZI';

insert INTO ZI (x, y, bid, uid) SELECT 100, 2, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 100, 3, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 100, 4, seq+1, 1 from sqlite_sequence where  name='ZI';

insert INTO ZI (x, y, bid, uid) SELECT 1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 0, 1, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT -1, 0, seq+1, 0 from sqlite_sequence where  name='ZI';
insert INTO ZI (x, y, bid, uid) SELECT 0, -1, seq+1, 0 from sqlite_sequence where  name='ZI';



select * from sqlite_sequence;

SELECT * from ZI;

DELETE FROM ZI;
update sqlite_sequence set seq = 0 where name = 'ZI';

