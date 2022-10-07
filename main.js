
// 配置
var beginPoint = { x: 0, y: 0 };
var gridSize = 25;
var stoneSize = 10;
var boardSize = 19;
var width = window.innerWidth,
    height = window.innerWidth;

// 全局变量
var uid = 0
var cursorPos = { x: 0, y: 0 }
var turn = 1; // 1 黑 or 2 白
var stones = new Map()

var _C = document.getElementById("C");
_C.setAttribute("width", width)
_C.setAttribute("height", width)
const ctx = _C.getContext('2d');

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
    stones = new Map()
}

function keyXY(pos) {
    return [pos.x, pos.y].join()
}
var makeMove = function (cursorPos, color) {
    stones.set(keyXY(cursorPos), color);
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
    ctx.fillRect(0, 0, width, height)
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
    let x1_ = parseInt(x1 / gridSize) - 1
    for (var x = gridSize * x1_; x <= x2; x += gridSize) {
        drawLine(x, y1, x, y2)
    }
    let y1_ = parseInt(y1 / gridSize) - 1
    for (var y = gridSize * y1_; y <= y2; y += gridSize) {
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
var startDragX = 0, startDragY = 0
_C.addEventListener("dragstart", function (event) {
    console.log('dragstart')
    startDragX = event.x; startDragY = event.y;
})
_C.addEventListener("dragend", function (event) {
    console.log('dargend')
    var x = event.x - startDragX, y = event.y - startDragY;
    console.log(x, y)
    beginPoint.x += x; beginPoint.y += y;
})
// for mobile
_C.addEventListener("touchstart", function (event) {
    startDragX = event.targetTouches[0].pageX; startDragY = event.targetTouches[0].pageY;
})
_C.addEventListener("touchmove", function (event) {
    var _x = event.targetTouches[0].pageX, _y = event.targetTouches[0].pageY;
    var x = _x - startDragX, y = _y - startDragY;
    beginPoint.x += x; beginPoint.y += y;
    startDragX = _x; startDragY = _y;
    event.preventDefault()
})
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
    }).then(function (r) {
        return r.json()
    }).then(function (r) {
        if (r.code === 0) {
            cb(r.data)
        } else {
            console.error(r.msg)
        }
    })
}
_C.addEventListener("click", function (event) {
    if (stones.has(keyXY(cursorPos))) {
        let u = stones.get(keyXY(cursorPos))
        set_uid(u)
    } else {
        console.log("doit", cursorPos.x, cursorPos.y, turn)
        makeMove(cursorPos, uid)
        doNetReq(cursorPos, () => { })
    }
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
function reMakeStones(lst) {
    for (let a of lst) {
        makeMove(a, a.uid)
    }
}
function refreshPan(lst, x1, y1, x2, y2) {
    if (lst !== undefined) {
        boardClear()
        reMakeStones(lst)
    } else {
        getPan(function (lst) {
            boardClear()
            reMakeStones(lst)
        }, x1, y1, x2, y2)
    }
}
function buildQuery(q) {
    let a = []
    for (let k in q) {
        a.push(k + '=' + encodeURIComponent(q[k]))
    }
    return a.join('&')
}
function getPan(cb, x1, y1, x2, y2) {
    let q = { x1, x2, y1, y2 }
    fetch("/getall?" + buildQuery(q)).then(function (res) {
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
function refreshPanZone() {
    let x = -beginPoint.x, y = -beginPoint.y
    let x1 = parseInt(x / gridSize) - 1, x2 = parseInt((x + width) / gridSize) + 1,
        y1 = parseInt(y / gridSize) - 1, y2 = parseInt((y + height) / gridSize) + 1;
    refreshPan(undefined, x1, y1, x2, y2)
}
function init() {
    boardClear();
    refreshPanZone();
    checkUIDAutoSet()
}
function step(timestamp) {
    drawBackground();
    // console.log('save')
    ctx.save();
    ctx.translate(beginPoint.x, beginPoint.y)
    drawPanel()
    drawCursor(cursorPos.x, cursorPos.y)
    let key = keyXY(cursorPos)
    let s = "(" + key + ")"
    if (stones.has(key)) {
        s += " uid = " + stones.get(keyXY(cursorPos))
    }
    statusBar.textContent = s
    // 画棋子
    stones.forEach((v, k) => {
        let [x, y] = k.split(',').map(x => parseInt(x, 10))
        drawStone(x, y, v)
    })

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
    refreshPanZone();
}
refreshPanTime()
