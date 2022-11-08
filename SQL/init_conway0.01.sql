-- 本项目开源地址为https://gitee.com/wu-org/go
-- 上述项目所有成果使用GPL2.0进行授权。
-- 在sqlite3 v3.39.4中执行本文件
-- 现实化的服务器地址是 http://124.221.142.162:8083/



DROP VIEW IF EXISTS NOW;
CREATE VIEW NOW AS
    select datetime('now','localtime') as value
;
SELECT * FROM NOW;


drop TABLE IF EXISTS ZI;
create table ZI(
    id INTEGER PRIMARY KEY autoincrement,
    x INT2 check(x >= -300 and x <= 299),
    y INT2 check(y >= -240 and y <= 239),
    bid UNSIGNED INT,
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


-- 落子之后发生的事情。
drop TRIGGER if EXISTS after_zi_insert_trigger;
CREATE TRIGGER after_zi_insert_trigger
AFTER INSERT
ON ZI
FOR EACH ROW
BEGIN
    -- 更新last_go_time变量
    UPDATE ENV SET value = (select value FROM NOW) WHERE name = 'last_go_time';
    -- UPDATE VAR SET last_zid = (select id FROM VIEW_LAST_ZI);
END;
-- SELECT * from ENV;

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


-- 需要insert的点是{p|N_3(p)}
DROP VIEW IF EXISTS positions_need_insert;
CREATE VIEW positions_need_insert AS
WITH
    N(x,y) as (
        SELECT x+1, y FROM ZI 
        union
        SELECT x+1, y+1 FROM ZI 
        union
        SELECT x, y+1 FROM ZI 
        union
        SELECT x-1, y+1 FROM ZI 
        union
        SELECT x-1, y FROM ZI 
        union
        SELECT x-1, y-1 FROM ZI 
        union
        SELECT x, y-1 FROM ZI 
        union
        SELECT x+1, y-1 FROM ZI             
        EXCEPT
        SELECT x, y FROM ZI
    )
    SELECT N.x, N.y, (
            SELECT uid 
            FROM ZI
            WHERE   (ZI.x BETWEEN ZI.x-1 AND ZI.x+1)
            AND     (ZI.y BETWEEN ZI.y-1 AND ZI.y+1)
            LIMIT 1
            ) as uid
    FROM N
    WHERE (
        WITH
            n8(x,y) as (
                SELECT N.x+1, N.y 
                union
                SELECT N.x+1, N.y+1 
                union
                SELECT N.x, N.y+1 
                union
                SELECT N.x-1, N.y+1 
                union
                SELECT N.x-1, N.y 
                union
                SELECT N.x-1, N.y-1 
                union
                SELECT N.x, N.y-1 
                union
                SELECT N.x+1, N.y-1 
                INTERSECT
                SELECT x, y FROM ZI
            )
            SELECT count(1)
            FROM n8
        ) = 3
;
-- select * from positions_need_insert;


-- 需要delete的点是{p|not(N_{2,3}(p))}
DROP VIEW IF EXISTS positions_need_delete;
CREATE VIEW positions_need_delete AS
    SELECT * 
    FROM ZI
    WHERE (
        WITH
            n8(x,y) as (
                SELECT ZI.x+1, ZI.y 
                union
                SELECT ZI.x+1, ZI.y+1 
                union
                SELECT ZI.x, ZI.y+1 
                union
                SELECT ZI.x-1, ZI.y+1 
                union
                SELECT ZI.x-1, ZI.y 
                union
                SELECT ZI.x-1, ZI.y-1 
                union
                SELECT ZI.x, ZI.y-1 
                union
                SELECT ZI.x+1, ZI.y-1 
                INTERSECT
                SELECT x, y FROM ZI
            )
            SELECT count(1)
            FROM n8
    )  not IN (2,3)
;
-- select * from positions_need_delete;

