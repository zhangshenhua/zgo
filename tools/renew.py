import sqlite3


conn = sqlite3.connect('../zi.db')
c = conn.cursor()
print ("数据库打开成功")

mins = c.execute("SELECT * from view_mins_ago").fetchall()[0][0]

print(mins)

if mins >= 60:
    c.execute(
        '''
        DELETE FROM ZI
        WHERE (ZI.x, ZI.y) in (
            WITH RECURSIVE
                X(v) as (
                    SELECT * from generate_series(0,18,1)
                ),
                Y(v) as (
                    SELECT * from generate_series(0,18,1)
                )   
                SELECT  X.v as x, Y.v as y
                FROM  X, Y  
            )
        '''
    )
    conn.commit()


print ("数据操作成功")
conn.close()