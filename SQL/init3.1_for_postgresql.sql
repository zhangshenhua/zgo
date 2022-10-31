-- 
/*
本项目开源地址为https://gitee.com/wu-org/go
上述项目所有成果使用GPL2.0进行授权。
本文件的算法现在【http://124.221.142.162:8082】上进行测试。
本文件为使图变更大棋盘多人围棋（http://124.221.142.162:8081/）的后台数据库而写，原本用得是sqlite数据库。

在postgresql13中执行本文件。建议使用pgAdmin4调试本文件。即按F5执行即可。

本文件的使用者应自行确保：
1.已创建了名为zi的数据库。
2.已创建名为zi的可登录角色并拥有1所述数据库。

以下操作都以zi这个角色在zi这个数据库上进行。

*/



DROP VIEW NOW CASCADE;
CREATE OR REPLACE VIEW NOW AS
    select  LOCALTIMESTAMP  as value
;
SELECT * FROM NOW;


drop TABLE IF EXISTS ZI CASCADE;
create table ZI(
    id SERIAL PRIMARY KEY,
    x INT2 check(x >= -10000 and x <= 10000),
    y INT2 check(y >= -10000 and y <= 10000),
    bid  bigint NOT NULL,
    uid  bigint NOT NULL ,
    Unique (x, y)
);
ALTER SEQUENCE zi_id_seq 
	AS bigint
	MINVALUE 0 
	START WITH 0; 
create unique INDEX index_zi_x_y on ZI (x,y);
create INDEX index_zi_x on ZI (x);
create INDEX index_zi_y on ZI (y);
CREATE INDEX index_bid ON ZI (bid);
CREATE INDEX index_uid ON ZI (uid);


-- 存放系统参数用的表
drop TABLE IF EXISTS ENV CASCADE;
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
    last_zid   bigint
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
    select bid, uid
    from VIEW_LAST_ADJOINING_ZI as ADJ
    GROUP BY bid, uid
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
        GROUP BY T1.uid, T1.bid
    ;

-- SELECT * FROM VIEW_RELATED_BLOCKS_QISHU;

-- 列出所有需要结算的块
CREATE OR REPLACE VIEW VIEW_NEED_CLEAR_BLOCKS AS
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
CREATE OR REPLACE FUNCTION need_clear()
    RETURNS boolean
    LANGUAGE 'sql'
    VOLATILE 
AS $BODY$
SELECT  exists( -- 存在没气的块
                SELECT  bid FROM VIEW_NEED_CLEAR_BLOCKS
            )
$BODY$;
-- select need_clear();


create or REPLACE FUNCTION f() returns integer
as $$
begin
    RETURN 1;
    RETURN 2;
end;
$$ LANGUAGE 'plpgsql';


-- 落子之后发生的事情。
CREATE or REPLACE FUNCTION after_zi_insert_trigger()
    RETURNS trigger
AS $BODY$
-- DECLARE ret ZI.bid%TYPE;
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

    IF need_clear() THEN
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

        IF FOUND  THEN
            return NULL;
        END IF;

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
        );
    END IF;
	return NULL;
END;
$BODY$ 
LANGUAGE 'plpgsql';



drop TRIGGER if EXISTS after_zi_insert_trigger on zi;
CREATE TRIGGER  after_zi_insert_trigger
AFTER INSERT
ON ZI
FOR EACH ROW
EXECUTE FUNCTION after_zi_insert_trigger();
-- SELECT * from ENV;


-- 最后落子时间
CREATE OR REPLACE VIEW VIEW_LAST_GO_TIME AS
    SELECT value FROM ENV WHERE name = 'last_go_time'
;
-- select * from VIEW_LAST_GO_TIME

-- 距离最后落子过去几分钟 
DROP VIEW if exists VIEW_MINS_AGO;
CREATE OR REPLACE VIEW VIEW_MINS_AGO AS
    SELECT  date_part('MINUTE', NOW.value - (T.value::timestamptz)) as value
    FROM NOW, VIEW_LAST_GO_TIME T
;
-- SELECT * FROM VIEW_MINS_AGO;


-- tests
-- DELETE FROM ZI;
-- select setval('zi_id_seq', 0);
-- SELECT currval('zi_id_seq');
-- insert INTO ZI (x, y, bid, uid) SELECT 1,  0, currval('zi_id_seq')+1,  0;
-- insert INTO ZI (x, y, bid, uid) SELECT 0,  1, currval('zi_id_seq')+1,  0;
-- insert INTO ZI (x, y, bid, uid) SELECT -1, 0, currval('zi_id_seq')+1,  0;
-- insert INTO ZI (x, y, bid, uid) SELECT 0, -1, currval('zi_id_seq')+1,  0;

-- insert INTO ZI (x, y, bid, uid) SELECT  0,  2, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  0, -2, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT -2,  0, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  2,  0, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT -1,  1, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT -1, -1, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  1,  1, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  1, -1, currval('zi_id_seq')+1, 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  0,  0, currval('zi_id_seq')+1, 2;

-- insert INTO ZI (x, y, bid, uid) SELECT 100, 2, currval('zi_id_seq')+1, 0;
-- insert INTO ZI (x, y, bid, uid) SELECT 100, 3, currval('zi_id_seq')+1, 0;
-- insert INTO ZI (x, y, bid, uid) SELECT 100, 4, currval('zi_id_seq')+1, 1;

-- insert INTO ZI (x, y, bid, uid) SELECT 1,   0, currval('zi_id_seq')+1, 0;
-- insert INTO ZI (x, y, bid, uid) SELECT 0,   1, currval('zi_id_seq')+1, 0;
-- insert INTO ZI (x, y, bid, uid) SELECT -1,  0, currval('zi_id_seq')+1, 0;
-- insert INTO ZI (x, y, bid, uid) SELECT 0,  -1, currval('zi_id_seq')+1, 0;
-- SELECT * from ZI;


-- -- tests DaJie
-- DELETE FROM ZI;
-- select setval('zi_id_seq', 0);
-- SELECT currval('zi_id_seq');
-- insert INTO ZI (x, y, bid, uid) SELECT  9,  8,   currval('zi_id_seq'), 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  8,  9,   currval('zi_id_seq'), 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  9,  10,  currval('zi_id_seq'), 1;
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  8,  currval('zi_id_seq'), 2;
-- insert INTO ZI (x, y, bid, uid) SELECT  11,  9,  currval('zi_id_seq'), 2;
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  10, currval('zi_id_seq'), 2;
-- insert INTO ZI (x, y, bid, uid) SELECT  9,   9,  currval('zi_id_seq'), 2;
-- insert INTO ZI (x, y, bid, uid) SELECT  10,  9,  currval('zi_id_seq'), 1;
-- SELECT * from ZI;


-- make border
INSERT INTO ZI(x, y, bid, uid)
SELECT 
        POS.x, 
        POS.y,
        (select last_value from zi_id_seq),
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

/*
后记：
这个版本虽然功能看上去是对的。但是它仍是不彻底的。高内聚低耦合没有进行到底。这是为了照顾现有程序，是的在迁移的过程中可以尽量少的去修改原有服务程序。
这个事情以后还是要实现的。事情不可以做一半，一定要一手一脚搞定。
VIEW_ZI是与"后端程序"的接口。"后端程序":
insert into VIEW_ZI(uid, x, y) values (<uid>, <x>, <y>); -- 块信息由数据库通过建在视图上的insteed触发器来维护
或者select * from VIEW_ZI;                               -- 布局信息由数据库负责给出
*/

/*
ALTER TABLE zi DISABLE TRIGGER ALL;
ALTER TABLE var DISABLE TRIGGER ALL;

\i backup.sql

ALTER TABLE zi ENABLE TRIGGER ALL;
ALTER TABLE var ENABLE TRIGGER ALL;
-------------------- OR -----------------------
SET session_replication_role = replica;

SET session_replication_role = DEFAULT;
*/