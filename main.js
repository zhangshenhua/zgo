var _C = document.getElementById("C");
const ctx = _C.getContext('2d');

// 配置
var beginPoint = { x: 0, y: 0 };
var gridSize = 25;
var stoneSize = 10;
var boardSize = 19;
var width = 800,
    height = 600;

// 全局变量
var uid = 0
var cursorPos = { x: 0, y: 0 }
var turn = 1; // 1 黑 or 2 白
var stones = []

// 各种函数
function get_uid() {
    return uid;
}
function set_uid(u) {
    if (u === undefined) {
        u = parseInt(0xffffff * Math.random()) + 1
    }
    u = parseInt(u)
    if (u < 0) {
        u = 0
    }
    localStorage.setItem("color", u.toString(16))
    return uid = u
}
function checkUIDAutoSet() {
    let c = localStorage.getItem("color")
    if (c === null) {
        c = set_uid()
    } else {
        set_uid(parseInt(c, 16))
    }
}
var toI = function (i, j) {
    return i * boardSize + j
}
var boardClear = function () {
    stones = []
}

var makeMove = function (cursorPos, turn) {
    // 落子
    cursorPos.uid = turn
    stones.push(cursorPos)
}
var isAllColor = function (lst, color) {
    for (let p of lst) {
        if (sget(p.x, p.y) != color) {
            return false;
        }
    }
    return true;
}

// ==== 以下是画图函数 ====

var drawBackground = function () {
    ctx.save();
    ctx.fillStyle = "white"
    ctx.fillRect(0, 0, 800, 600)
    ctx.restore();
}
var drawLine = function (x1, y1, x2, y2) {
    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x2, y2);
    ctx.closePath();
    ctx.stroke();
}
// draw in rect
var drawLines = function (x1, y1, x2, y2) {
    for (var x = gridSize * (parseInt(x1 / gridSize) - 1); x <= x2; x += gridSize) {
        drawLine(x, y1, x, y2)
    }
    for (var y = gridSize * (parseInt(y1 / gridSize) - 1); y <= y2; y += gridSize) {
        drawLine(x1, y, x2, y)
    }
}
var drawStar = function (x, y) {
    ctx.beginPath();

    var radius = 4; // 圆弧半径
    var startAngle = 0; // 开始点
    var endAngle = 2 * Math.PI; // 结束点
    var anticlockwise = false; // 顺时针或逆时针

    ctx.arc(x, y, radius, startAngle, endAngle, anticlockwise);

    ctx.fill();
}
// drawStar(10, 10);
var drawStars = function () {
    var n = 3;
    for (var i = 0; i < n; i++) {
        var x = 3 * gridSize + i * (6 * gridSize);
        for (var j = 0; j < n; j++) {
            var y = 3 * gridSize + j * (6 * gridSize);
            drawStar(x, y)
        }
    }
}
var drawPanel = function (n) {
    var x1 = -beginPoint.x, x2 = -beginPoint.x + width,
        y1 = -beginPoint.y, y2 = -beginPoint.y + height;
    // console.log('draw in ', x1, y1,x2,y2)
    drawLines(x1, y1, x2, y2)
    drawStars()
}
// drawPanel(boardSize)

var drawCursor = function (x, y) {
    ctx.save()
    var x = x * gridSize;
    var y = y * gridSize
    ctx.beginPath();

    var radius = 6; // 圆弧半径
    var startAngle = 0; // 开始点
    var endAngle = 2 * Math.PI; // 结束点
    var anticlockwise = false; // 顺时针或逆时针

    ctx.arc(x, y, radius, startAngle, endAngle, anticlockwise);

    ctx.strokeStyle = 'red'
    ctx.stroke();
    ctx.restore();
}
// drawCursor(10, 10)

var drawStone = function (x, y, color) {
    ctx.save()
    var x = x * gridSize;
    var y = y * gridSize
    ctx.beginPath();

    var radius = stoneSize; // 圆弧半径
    var startAngle = 0; // 开始点
    var endAngle = 2 * Math.PI; // 结束点
    var anticlockwise = false; // 顺时针或逆时针

    ctx.arc(x, y, radius, startAngle, endAngle, anticlockwise);

    ctx.strokeStyle = 'black'
    ctx.stroke();
    ctx.fillStyle = userColor(color)
    ctx.fill();

    ctx.restore();
}
var drawStoneAbs = function (x, y, color) {
    ctx.save()
    ctx.beginPath();

    var radius = stoneSize; // 圆弧半径
    var startAngle = 0; // 开始点
    var endAngle = 2 * Math.PI; // 结束点
    var anticlockwise = false; // 顺时针或逆时针

    ctx.arc(x, y, radius, startAngle, endAngle, anticlockwise);

    ctx.strokeStyle = 'black'
    ctx.stroke();
    ctx.fillStyle = color == 1 ? 'black' : 'white'
    ctx.fill();

    ctx.restore();
}

_C.addEventListener("mousemove", function (event) {
    // console.log(event.x-beginPoint.x,event.y-beginPoint.y)
    var x = event.x - beginPoint.x;
    var y = event.y - beginPoint.y
    var i = x >= 0 ? parseInt(x / gridSize) : parseInt(x / gridSize) - 1;
    var j = y >= 0 ? parseInt(y / gridSize) : parseInt(y / gridSize) - 1;
    cursorPos.x = i; cursorPos.y = j;
    // console.log(cursorPos);
})
function doNetReq(pos, cb) {
    pos.uid = uid
    fetch("/doit", {
        method: "POST",
        body: JSON.stringify(pos)
    }).then(cb)
}
_C.addEventListener("click", function (event) {
    console.log("doit", cursorPos.x, cursorPos.y, turn)

    makeMove(cursorPos, uid)
    doNetReq(cursorPos, refreshPan)
})
document.body.addEventListener("keypress", function (event) {
    // console.log(event.key)
    var step = 10;
    if (event.key === "a") {
        beginPoint.x += step;
    } else if (event.key === "d") {
        beginPoint.x -= step;
    } else if (event.key === 'w') {
        beginPoint.y += step;
    } else if (event.key === 's') {
        beginPoint.y -= step;
    }
})
function refreshPan(lst) {
    getPan(function (lst) {
        // console.log(lst)
        boardClear()
        stones = lst
    })
}
function getPan(cb) {
    fetch("/getall").then(function (res) {
        return res.json()
    }).then(function (j) {
        cb(j)
    })
}

function userColor(uid) {
    var s = uid.toString(16)
    return '#' + s.padStart(6, "0")
}
var statusBar = document.getElementById("statusBar")
function init() {
    boardClear();
    refreshPan()
    checkUIDAutoSet()
}
function step(timestamp) {
    drawBackground();
    // console.log('save')
    ctx.save();
    ctx.translate(beginPoint.x, beginPoint.y)
    drawPanel()
    drawCursor(cursorPos.x, cursorPos.y)
    statusBar.textContent = "(" + cursorPos.x + "," + cursorPos.y + ")"
    // 画棋子
    for (let s of stones) {
        drawStone(s.x, s.y, s.uid)
    }

    // 当前棋子颜色
    // drawStoneAbs((boardSize + 1) * gridSize, 1 * gridSize, turn);
    ctx.restore()
    // console.log('restore')

    window.requestAnimationFrame(step);
}
init();
window.requestAnimationFrame(step);
function refreshPanTime() {
    setTimeout(refreshPanTime, 3000)
    refreshPan()
}
refreshPanTime()
