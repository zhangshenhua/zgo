-- 参照delete_block而写delete_rect，后者作为前者的补充。
-- 根据标准棋盘5、6、7、8行(即星位下面连续的四行)的二进制表示移除大棋盘上的子。
-- 5 --> x1, 6 --> y1, 7 --> x2, 8 --> y2。
-- 可以考虑每10分钟执行一次。

DELETE
FROM zi
WHERE (
    (
        x
        BETWEEN
        (
              EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 4) * 1
            + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 4) * 2
            + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 4) * 4
            + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 4) * 8
            + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 4) * 16
            + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 4) * 32
            + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 4) * 64
            + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 4) * 128
            + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 4) * 256
            + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 4) * 512
            + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 4) * 1024
            + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 4) * 2048
            + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 4) * 4096
            + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 4) * 8192
        ) 
        AND 
        (
              EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 6) * 1
            + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 6) * 2
            + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 6) * 4
            + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 6) * 8
            + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 6) * 16
            + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 6) * 32
            + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 6) * 64
            + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 6) * 128
            + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 6) * 256
            + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 6) * 512
            + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 6) * 1024
            + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 6) * 2048
            + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 6) * 4096
            + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 6) * 8192
        )
    )
    AND
    (
        y
        BETWEEN
        (
              EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 5) * 1
            + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 5) * 2
            + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 5) * 4
            + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 5) * 8
            + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 5) * 16
            + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 5) * 32
            + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 5) * 64
            + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 5) * 128
            + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 5) * 256
            + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 5) * 512
            + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 5) * 1024
            + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 5) * 2048
            + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 5) * 4096
            + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 5) * 8192
        ) 
        AND 
        (
              EXISTS(SELECT 1 FROM zi WHERE x = 18 and y = 7) * 1
            + EXISTS(SELECT 1 FROM zi WHERE x = 17 and y = 7) * 2
            + EXISTS(SELECT 1 FROM zi WHERE x = 16 and y = 7) * 4
            + EXISTS(SELECT 1 FROM zi WHERE x = 15 and y = 7) * 8
            + EXISTS(SELECT 1 FROM zi WHERE x = 14 and y = 7) * 16
            + EXISTS(SELECT 1 FROM zi WHERE x = 13 and y = 7) * 32
            + EXISTS(SELECT 1 FROM zi WHERE x = 12 and y = 7) * 64
            + EXISTS(SELECT 1 FROM zi WHERE x = 11 and y = 7) * 128
            + EXISTS(SELECT 1 FROM zi WHERE x = 10 and y = 7) * 256
            + EXISTS(SELECT 1 FROM zi WHERE x = 9  and y = 7) * 512
            + EXISTS(SELECT 1 FROM zi WHERE x = 8  and y = 7) * 1024
            + EXISTS(SELECT 1 FROM zi WHERE x = 7  and y = 7) * 2048
            + EXISTS(SELECT 1 FROM zi WHERE x = 6  and y = 7) * 4096
            + EXISTS(SELECT 1 FROM zi WHERE x = 5  and y = 7) * 8192
        )
    )
)
RETURNING *;
