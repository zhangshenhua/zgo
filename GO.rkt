#lang racket

(require racket/set)
(require db)
(require sql)


(define c (sqlite3-connect #:database "mygo.sqlite"))
(define my-query-list (curry query-list c))


#;
(所谓棋局就是棋块的集合。一个棋块只属于某个玩家ID。
   所以总体上可以定义成以玩家ID为key的hash。
   而value则是该玩家所有棋块的集合。
   而棋块又是棋子的集合。
   棋子具有坐标以及其他属性。)

;;已占？
#;
(define occupied?
  (lambda (x y)
    (query-maybe-value c
                     "select rowid from zi where x=$1 and y=$2" x y)))


;;并块
#;
(define merge-blocks!
  (lambda (bid-list)
    (let ((fst-bid (car bid-list)))
      (for/list ((bid (cadr bid-list)))
        (query-exec c
                    "update zi set bid = $1 where bid = $2"
                    fst-bid bid)))))



;;清算
;;每落下一子都触发清算
;;清算的结果是应提尽提
;;步骤是:
;;1.落下子a并为其分配新的bid。
;;2.将bid（这个单点块）与其相邻的己方块合成一块(记作Ba)。
;;3.提走与a相邻的非己方块中气归0的，GOTO 5。
;;4.若Ba气尽则提走之。
;;5.END
#;
(define CLEAR!
  (lambda (player-id x y)
    ;;1
    (query-exec c
                "insert INTO ZI (uid, x, y, bid )
                 SELECT $1 , $2, $3,  seq+1
                 from sqlite_sequence where  name='ZI';"
                player-id x y)
    
    (define bid (query-value c
                             "select seq from sqlite_sequence where  name='ZI';"))
    bid
    ;;2
    (query-exec c
                "update ZI
                 set bid = ")
    ))


;;落子
#;
(define GO!
  (lambda (player-id x y)
    (call/cc
     (lambda (return)
       (let ((occupied (occupied? x y)))
         (when occupied  ;;如果该点被占据
           (return 'failed-occupied))
         (CLEAR! player-id x y)
         )))))

(define Truncate!
  (lambda ()
    (query-exec c
                "delete from ZI;")
    (query-exec c
                "update sqlite_sequence set seq = 0 where name = 'ZI';")
    'Truncate!-OK))


(define GO!
  (lambda (player-id x y)
    (query-exec c
                "insert INTO ZI (uid, x, y, bid)
                 SELECT $1, $2, $3, seq+1
                 from sqlite_sequence
                 where  name='ZI';"
                player-id x y)
    1
    ))


1111

(define init-db
  (lambda ()
    (query-list c
     "select date();"
    )
    (Truncate!)
    (GO! 0 0 0)
    (GO! 0 1 0)
    (GO! 0 0 1)
    (GO! 0 -1 0)
    (GO! 0 0 -1)
    ))
(init-db)



(query-rows c
            "select * from zi")
#|

(query-rows c
            "select * from sqlite_sequence")

      
(query-exec c
            "INSERT INTO ZI (uid, x, y, bid) VALUES (8, 8, 8, 8)"
            )


(query-exec c
            (insert #:into ZI #:con(x y)
                    #:from (select 8 8 8 (+ seq 1)
                                   #:from sqlite_sequence
                                   #:where (= name "ZI")))
            )


(insert #:into ZI
        #:from (select 8 8 8 (+ seq 1)
                       #:from sqlite_sequence
                       #:where (= name "ZI")))

|#
