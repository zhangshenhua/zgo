/*
接口约定：
    走棋
        向服务器发送(uid,x,y)
        服务器回应是否成功落子

    看棋
        向服务器发送(uid,x0,y0)
        服务器返回
            select uid,x,y
            from ZI
            where (x >= x0 - 10 or x <= x0 - 10)
              and (y >= y0 - 10 or y <= x0 - 10)

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




var sqlite3 = require('sqlite3').verbose();
var db = new sqlite3.Database('abcd');

db.serialize(function() {
    db.run("CREATE TABLE user (id INT, dt TEXT)");

    var stmt = db.prepare("INSERT INTO user VALUES (?,?)");
    for (var i = 0; i < 10; i++) {
        var d = new Date();
        var n = d.toLocaleTimeString();
        stmt.run(i, n);
    }
    stmt.finalize();

    db.each("SELECT id, dt FROM user", function(err, row) {
        console.log("User id : "+row.id, row.dt);
    });
});

db.close();


