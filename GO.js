/*
接口约定：
    走棋
        向服务器发送(uid,x,y)
        服务器回应是否成功落子

    看棋
        向服务器发送(uid,x,y)
*/



const sqlite3 = require('sqlite3');
sqlite3.verbose()

var db = new sqlite3.Database('mygo.sqlite.db')

//db.run("")

var GO = function(uid, x, y) {
    db.run(`insert INTO ZI (uid, x, y, bid) 
             SELECT ?, ?, ?, seq+1
             from sqlite_sequence where  name='ZI';`,
             uid, x, y)
}


//GO(0,0,0)

/*
db.all("select * from ZI",[],
    function(err, res) {
        console.log(JSON.stringify(res))
    }

)
*/
var res

db.all("select * from ZI",[],
    (err,rows)=>{
        console.log(rows)
        res = rows
    })

console.log(JSON.stringify(res) )


