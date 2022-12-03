-- 所有无气的块
DROP VIEW IF EXISTS VIEW_BLOCKS_HAS_NO_QI;
CREATE VIEW VIEW_BLOCKS_HAS_NO_QI as
    WITH RECURSIVE
        B(bid) as (
            select bid 
            from zi
            group by bid
        )
        select * 
        from B
        where NOT EXISTS( -- bid所指的块无气
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

-- 删除所有无气的块
with 
    B(bid) as (
        select bid from VIEW_BLOCKS_HAS_NO_QI
    )
DELETE from zi where zi.bid = B.bid;

