from operator import imod
import sqlite3
import os

conn = sqlite3.connect('../zi.db')
c = conn.cursor()
print ("数据库打开成功")

mins = c.execute("SELECT * from view_mins_ago").fetchall()[0][0]

print(mins)

if mins >= 60:
    # c.execute(
    #     '''
    #     DELETE FROM ZI
    #     WHERE (ZI.x, ZI.y) in (
    #         SELECT * FROM VIEW_STD_AREA
    #         )
    #     '''
    # )
    # conn.commit()
    os.system('sqlite3 ../zi.db < renew.sql')

print ("数据操作成功")
conn.close()
