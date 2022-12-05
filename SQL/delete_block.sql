-- 删除(x, y)所在的块
-- x由19*19第一行的二进制形式表征，y由9*19第二行的二进制形式表征
-- 由于x>=0,y>=0所以这个操作的对象限定为一个象限中的子，但是如果这个子连接到其他象限，那么也会一并提取。
-- 这个程序考虑一小时执行一次

DROP view if exists view_pos_x;
CREATE VIEW view_pos_x AS
    SELECT 
          EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 0) * 1
        + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 0) * 2
        + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 0) * 4
        + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 0) * 8
        + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 0) * 16
        + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 0) * 32
        + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 0) * 64
        + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 0) * 128
        + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 0) * 256
        + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 0) * 512
        + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 0) * 1024
        + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 0) * 2048
        + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 0) * 4096
        + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 0) * 8192
        as value
;

DROP view if exists view_pos_y;
CREATE VIEW view_pos_y AS
    SELECT 
          EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 2) * 1
        + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 2) * 2
        + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 2) * 4
        + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 2) * 8
        + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 2) * 16
        + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 2) * 32
        + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 2) * 64
        + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 2) * 128
        + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 2) * 256
        + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 2) * 512
        + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 2) * 1024
        + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 2) * 2048
        + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 2) * 4096
        + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 2) * 8192
        as value
;


DELETE 
FROM zi 
WHERE bid = (select bid 
            FROM ZI 
            where x = (SELECT value from view_pos_x) and y = (SELECT value from view_pos_y)
    )
RETURNING *;