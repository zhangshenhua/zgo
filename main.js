var _C = document.getElementById("C");
const ctx = _C.getContext('2d');

// 配置
var beginPoint = { x: 20, y: 20 };
var gridSize = 25;
var stoneSize = 10;
var boardSize = 19;
// var colorTable = [

// 全局变量
var uid = 0
var cursorPos = { x: 0, y: 0 }
var turn = 1; // 1 黑 or 2 白
var stones = new Array(boardSize * boardSize)
// [sg] ; sg::={ color: color, stones: Map, qis: Map} ; Map::=[int:{x,y}]
var stoneGroups = new Array();

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
    uid = u % 0xffffff
    return "0x" + uid.toString(16)
}
var toI = function (i, j) {
    return i * boardSize + j
}
var sget = function (i, j) {
    return stones[i * boardSize + j]
}
var sset = function (i, j, color) {
    stones[i * boardSize + j] = color
}
var boardClear = function () {
    for (var i = 0; i < boardSize; i++) {
        for (var j = 0; j < boardSize; j++) {
            sset(i, j, -1)
        }
    }
    stoneGroups = [];
}

var makeMove = function (cursorPos, turn) {
    // 落子
    sset(cursorPos.x, cursorPos.y, turn)
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
// drawLine(10, 10, 100, 100)
var drawLines = function (n) {
    var lastLine = (n - 1) * gridSize;
    for (var i = 0; i < n; i++) {
        var x = i * gridSize;
        drawLine(x, 0, x, lastLine)
    }
    for (var i = 0; i < n; i++) {
        var y = i * gridSize;
        drawLine(0, y, lastLine, y)
    }
}
// drawLines(19);
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
    ctx.translate(beginPoint.x, beginPoint.y)
    drawLines(n)
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
    var i = parseInt(x / gridSize);
    var j = parseInt(y / gridSize);
    cursorPos.x = i; cursorPos.y = j;
    // console.log(cursorPos);
    // console.log(findNeighbors(i,j))
})
function doNetReq(pos, cb) {
    pos.uid = uid
    fetch("/doit", {
        method: "POST",
        body: JSON.stringify(pos)
    }).then(cb)
}
_C.addEventListener("click", function (event) {
    // console.log("i,j", cursorPos.x, cursorPos.y)
    if (cursorPos.x < boardSize && cursorPos.y < boardSize) {
        // console.log("i,j", i, j)
        if (sget(cursorPos.x, cursorPos.y) === -1) {
            oldsgs = stoneGroups

            console.log("doit", cursorPos.x, cursorPos.y, turn)

            makeMove(cursorPos, uid)
            doNetReq(cursorPos, refreshPan)
        }
    }
})
function refreshPan() {
    getPan(function (lst) {
        console.log(lst)
        boardClear()
        for (let st of lst) {
            sset(st.x, st.y, st.uid)
        }
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
}
function step(timestamp) {
    ctx.save();
    drawBackground();
    drawPanel(boardSize)
    if (cursorPos.x < boardSize && cursorPos.y < boardSize) {
        drawCursor(cursorPos.x, cursorPos.y)
        statusBar.textContent = "(" + cursorPos.x + "," + cursorPos.y + ") uid = 0x" + sget(cursorPos.x, cursorPos.y).toString(16)
    }
    // 画棋子
    for (var i = 0; i < boardSize; i++) {
        for (var j = 0; j < boardSize; j++) {
            if (sget(i, j)!==-1) {
                drawStone(i, j, sget(i, j))
            }
        }
    }

    // 当前棋子颜色
    // drawStoneAbs((boardSize + 1) * gridSize, 1 * gridSize, turn);

    ctx.restore()

    window.requestAnimationFrame(step);
}
init();
window.requestAnimationFrame(step);