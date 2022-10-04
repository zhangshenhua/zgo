package main

import (
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

type gozi struct {
	X   int `json:"x"`
	Y   int `json:"y"`
	Bid int `json:"bid"`
	Uid int `json:"uid"`
}

func getNextBid(db *sql.Tx) (nb int) {
	sql := fmt.Sprintf("SELECT max(bid) from zi")
	err := db.QueryRow(sql).Scan(&nb)
	if err != nil {
		return 1
	}
	return nb + 1
}
func getAll(db *sql.DB) []gozi {
	rows, err := db.Query("SELECT x,y,bid,uid from ZI")
	if err != nil {
		log.Fatal("db error in getall: ", err)
	}
	a := make([]gozi, 0)
	for rows.Next() {
		var x, y, bid, uid int
		rows.Scan(&x, &y, &bid, &uid)
		a = append(a, gozi{x, y, bid, uid})
	}
	return a
}
func getCol(db *sql.Tx, sql string, args ...interface{}) (a []int) {
	rows, err := db.Query(sql, args...)
	if err != nil {
		log.Fatal("db error : ", err)
	}
	for rows.Next() {
		var x int
		rows.Scan(&x)
		a = append(a, x)
	}
	return a
}
func getXYs(db *sql.Tx, q string, args ...interface{}) (a [][]int) {
	fmt.Printf("%s %v\n", q, args)
	rows, err := db.Query(q, args...)
	if err != nil {
		log.Fatal("db error : ", err)
	}
	for rows.Next() {
		var x, y int
		rows.Scan(&x, &y)
		a = append(a, []int{x, y})
	}
	return a
}

var flagDBFile string

func init() {
	flag.StringVar(&flagDBFile, "dbfile", "zi.db", "file path for sqlite db")
	flag.Parse()
}
func getVal(tx *sql.Tx, q string, args ...interface{}) (a int) {
	fmt.Printf("%s %v\n", q, args)
	row := tx.QueryRow(q, args...)
	err := row.Scan(&a)
	if err == sql.ErrNoRows {
		return 0
	}
	if err != nil {
		log.Fatal("db error : ", err)
	}
	return a
}

func insertDoDB(tx *sql.Tx, data gozi) error {
	nb := getNextBid(tx)
	sql := fmt.Sprintf(`insert INTO ZI (x, y, bid, uid) values (?,?,?,?)`)
	_, err := tx.Exec(sql, data.X, data.Y, nb, data.Uid)
	if err != nil {
		return err
	}
	return nil
	// step 1
	q := `UPDATE ZI 
		SET bid = (select min(OWN.bid) from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
		where ZI.bid in (select OWN.bid from VIEW_LAST_RELATED_OWN_BLOCKS as OWN)
		;`
	_, err = tx.Exec(q)
	if err != nil {
		return err
	}
	// step 2
	d := 0
	qun := `SELECT x, y-1 FROM (%s) 
					UNION
					SELECT x, y+1 FROM (%s)
					UNION
					SELECT x-1, y FROM (%s)
					UNION
					SELECT x+1, y FROM (%s)`
	for _, bid := range getCol(tx, "select *from VIEV_LAST_RELATED_ENEMY_BLOCKS") {
		q_ := "select x,y from zi where bid=?"
		q = fmt.Sprintf(qun, q_, q_, q_, q_)
		n := len(getXYs(tx, q, bid, bid, bid, bid))
		q1 := fmt.Sprintf(`SELECT count(*) from zi where (x,y) in (%s)`, q)
		nzi := getVal(tx, q1, bid, bid, bid, bid)
		fmt.Printf("%d=?=%d\n", n, nzi)
		if n == nzi {
			_, err := tx.Exec("delete from zi where bid=?", bid)
			if err != nil {
				log.Printf("%s %v\n", "delete from zi where bid=?", bid)
				return err
			}
			d += 1
		}
	}
	// step 3
	if d > 0 {
		q = `DELETE FROM ZI
			where bid in (
					SELECT B.bid
					FROM VIEW_LAST_RELATED_OWN_BLOCKS as B 
					WHERE NOT EXISTS (
						WITH RECURSIVE
							XY_IN_B(x,y) as (
								select ZI.x, ZI.y 
								FROM ZI JOIN VIEW_LAST_RELATED_OWN_BLOCKS as B ON ZI.bid = B.bid
							),
							NEIGHBORS_B(x,y) as (
								SELECT x, y-1 FROM XY_IN_B 
								UNION
								SELECT x, y+1 FROM XY_IN_B
								UNION
								SELECT x-1, y FROM XY_IN_B
								UNION
								SELECT x+1, y FROM XY_IN_B
							),
							QI(x,y) as (
								SELECT N.x, N.y
								FROM ZI, NEIGHBORS_B as N
								WHERE NOT EXISTS (select 1 
												from ZI 
												where ZI.x = N.x
													and ZI.y = N.y)
							)
						select 1 from QI
					)
				)
		;`
		_, err := tx.Exec(q)
		if err != nil {
			log.Printf("%s\n", q)
			return err
		}
	}
	return nil
}
func main() {
	log.SetFlags(log.Llongfile | log.LstdFlags)

	db, err := sql.Open("sqlite3", flagDBFile)

	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()

	var version string
	err = db.QueryRow("SELECT SQLITE_VERSION()").Scan(&version)

	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("SQLITE_VERSION:", version)

	http.Handle("/", http.FileServer(http.Dir(".")))
	http.HandleFunc("/getall", func(w http.ResponseWriter, r *http.Request) {
		a := getAll(db)
		ab, err := json.Marshal(a)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Fprintf(w, "%s", string(ab))

	})
	http.HandleFunc("/doit", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf("/doit\n")
		err := r.ParseForm()
		if err != nil {
			fmt.Fprintf(w, "%s", err)
			return
		}
		formData := gozi{}
		json.NewDecoder(r.Body).Decode(&formData)
		tx, err := db.Begin()
		if err != nil {
			fmt.Fprintf(w, "%s", err)
			return
		}
		err = insertDoDB(tx, formData)
		if err != nil {
			tx.Rollback()
			log.Printf("%s\n", err)
			fmt.Fprintf(w, "%s", err)
			return
		}
		a := getAll(db)
		ab, err := json.Marshal(a)
		if err != nil {
			log.Fatal(err)
		}
		err = tx.Commit()
		if err != nil {
			fmt.Fprintf(w, "%s", err)
			return
		}
		fmt.Fprintf(w, "%s", ab)
	})
	http.HandleFunc("/testpage", func(w http.ResponseWriter, r *http.Request) {
		fr, err := os.Open("index.html")
		if err != nil {
			log.Fatal(err)
		}
		buf := make([]byte, 4096)
		_, err = io.CopyBuffer(w, fr, buf)
		if err != nil {
			log.Fatal(err)
		}
	})
	log.Fatal(http.ListenAndServe(":8081", nil))
}
