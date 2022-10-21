




-- 所有棋块的气
with RECURSIVE
    B(id, uid, qi) as (
        SELECT bid, uid, count(*)
        from ZI
        GROUP by bid
    )
    SELECT * 
    from B
    ORDER by qi desc
;    





-------------------------------------------------
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
    -- select * from NEIGHBORS_B
    SELECT  -- R.uid, 
        T1.uid, T1.bid, count(T1.bid) as QiShu
    FROM    
        -- VIEW_LAST_RELATED_BLOCKS L LEFT JOIN 
        NEIGHBORS_B T1 
        LEFT JOIN ZI
        ON T1.bid = ZI.bid 
            and T1.uid = zi.uid
            AND (
                   (T1.x = zi.x + 1 and T1.y = zi.y) 
                or (T1.x = zi.x - 1 and T1.y = zi.y)
                or (T1.x = zi.x and T1.y = zi.y + 1)
                or (T1.x = zi.x and T1.y = zi.y - 1))
            -- and (T1.x, T1.y) not in (
            --     SELECT x,y from zi
            -- )
            and NOT EXISTS (select 1 
                            from ZI 
                            where ZI.x = T1.x
                            and ZI.y = T1.y)

    GROUP BY T1.bid
;









select * 
from (SELECT 0 union SELECT 1) 
JOIN (SELECT 0 union SELECT 1) 
JOIN (SELECT 0 union SELECT 1)  
JOIN (SELECT 0 union SELECT 1)  
JOIN (SELECT 0 union SELECT 1) 
JOIN (SELECT 0 union SELECT 1)  
JOIN (SELECT 0 union SELECT 1) 
JOIN (SELECT 0 union SELECT 1) 


WITH RECURSIVE
    Q as (

    )





-- select * from zi;

SELECT * from zi WHERE x=9 and y=9;

-- EXPLAIN
WITH RECURSIVE
    N0(uid, x, y) as ( -- 我
        select uid, x, y from VIEW_LAST_ZI
    ),
    N1(uid, x, y) as ( -- 东
        select zi.uid, zi.x, zi.y 
        from N0 INNER JOIN zi ON zi.x = N0.x + 1 and zi.y = N0.y
    ),
    N2(uid, x, y) as ( -- 北
        select zi.uid, zi.x, zi.y 
        from N0 INNER JOIN zi ON zi.x = N0.x and zi.y = N0.y + 1
    ),
    N3(uid, x, y) as ( -- 西
        select zi.uid, zi.x, zi.y 
        from N0 INNER JOIN zi ON zi.x = N0.x - 1 and zi.y = N0.y
    ),
    N4(uid, x, y) as ( -- 南
        select zi.uid, zi.x, zi.y 
        from N0 INNER JOIN zi ON zi.x = N0.x    and zi.y = N0.y - 1
    ),
    q0 as (
        select (NOT EXISTS (
                    select 1 from zi where zi.x = N1.x and zi.y = N1.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N2.x and zi.y = N2.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N3.x and zi.y = N3.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N4.x and zi.y = N4.y
                    ))
    ),
    q1 as (
        select (NOT EXISTS (
                    select 1 from zi where zi.x = N1.x and zi.y = N1.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N2.x and zi.y = N2.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N3.x and zi.y = N3.y
                    )) 
            or (NOT EXISTS (
                    select 1 from zi where zi.x = N4.x and zi.y = N4.y
                    ))
    ),    
    N5(x, y) as ( 
        SELECT x, y FROM LAST
        UNION
        SELECT x, y-1 FROM LAST 
        UNION
        SELECT x, y+1 FROM LAST
        UNION
        SELECT x-1, y FROM LAST
        UNION
        SELECT x+1, y FROM LAST)
        select ZI.* 
        from N5 INNER JOIN ZI ON ZI.x = N5.x and ZI.y = N5.y
    ),
    Ba(uid, x, y) as (
        select uid, x, y FROM VIEW_LAST_ZI
        UNION
        SELECT ZI.uid, ZI.x, ZI.y 
        FROM ZI inner join Ba ON Ba.x = ZI.x + 1 AND  Ba.y = ZI.y     AND Ba.uid = ZI.uid
        UNION
        SELECT ZI.uid, ZI.x, ZI.y 
        FROM ZI inner join Ba ON Ba.x = ZI.x     AND  Ba.y = ZI.y + 1 AND Ba.uid = ZI.uid
        UNION
        SELECT ZI.uid, ZI.x, ZI.y 
        FROM ZI inner join Ba ON Ba.x = ZI.x - 1 AND  Ba.y = ZI.y     AND Ba.uid = ZI.uid
        UNION
        SELECT ZI.uid, ZI.x, ZI.y 
        FROM ZI inner join Ba ON Ba.x = ZI.x     AND  Ba.y = ZI.y - 1 AND Ba.uid = ZI.uid
    ),
    NBa(x, y) as (
        SELECT x+1, y   FROM Ba 
        UNION
        SELECT x,   y+1 FROM Ba
        UNION
        SELECT x-1, y   FROM Ba
        UNION
        SELECT x,   y-1 FROM Ba
    ),
    Qi_a(x, y) as (
        SELECT x, y from NBa
        EXCEPT
        SELECT ZI.x, ZI.y from ZI INNER JOIN NBa ON Zi.x = NBa.x and ZI.y = NBa.y
    ),
    Qi_a2(x, y) as (
        SELECT x, y from NBa
        WHERE (x,y) not in (select x,y from ZI)
    )   
    select EXISTS(SELECT * from Qi_a2)
    ;










CREATE VIEW ALLDEADBLOCKS AS 
    SELECT * 
    FROM ZI
    ;




DROP VIEW IF EXISTS ALL_BLOCKS;
CREATE VIEW ALL_BLOCKS AS
    select bid
    from ZI
    group by bid
    ;

-- select * from ALL_BLOCKS;

DROP VIEW IF EXISTS ALL_BLOCKS_QISHU;
CREATE VIEW ALL_BLOCKS_QISHU AS
    WITH
        -- XY_IN_B(uid, bid, x, y) as ( -- 相关敌块中所有子的坐标
        --     select ZI.uid, ZI.bid, ZI.x, ZI.y 
        --     FROM ZI 
        --     -- JOIN ALL_BLOCKS as B ON ZI.bid = B.bid
        -- ),
        NEIGHBORS_B(uid, bid, x, y) as (
            SELECT uid, bid, x, y-1 FROM ZI 
            UNION
            SELECT uid, bid, x, y+1 FROM ZI
            UNION
            SELECT uid, bid, x-1, y FROM ZI
            UNION
            SELECT uid, bid, x+1, y FROM ZI
        )
        SELECT  -- R.uid, 
                T1.uid, T1.bid, count(ZI.id) as QiShu
        FROM    
            -- VIEW_LAST_RELATED_BLOCKS L LEFT JOIN 
            NEIGHBORS_B T1 LEFT JOIN ZI
            ON T1.bid = ZI.bid 
                and NOT EXISTS (select 1 
                                from ZI 
                                where ZI.x = T1.x
                                and ZI.y = T1.y)
        GROUP BY T1.bid
;

select * from ALL_BLOCKS_QISHU;
    

-- 提走所有无气的块
    DELETE FROM ZI
    where bid in ( -- 无气的块
        select bid
        from zi
        where (

        ) = 0
    )