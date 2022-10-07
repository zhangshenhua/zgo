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
	"strconv"

	_ "github.com/mattn/go-sqlite3"
)

type gozi struct {
	X   int `json:"x"`
	Y   int `json:"y"`
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
func getAll(db *sql.DB, x1, y1, x2, y2 int) []gozi {
	rows, err := db.Query(`SELECT x,y,bid,uid from ZI 
		where x>=?and x<=? and y>=? and y<=?`,
		x1, x2, y1, y2)
	if err != nil {
		log.Fatal("db error in getall: ", err)
	}
	a := make([]gozi, 0)
	for rows.Next() {
		var x, y, bid, uid int
		rows.Scan(&x, &y, &bid, &uid)
		a = append(a, gozi{x, y, uid})
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
}

type gores struct {
	Code int    `json:"code"`
	Msg  string `json:"msg"`
	Data []gozi `json:"data"`
}

func makeRes(code int, msg string, data []gozi) []byte {
	b, err := json.Marshal(gores{code, msg, data})
	if err != nil {
		log.Fatal(err)
	}
	return b
}
func writeResErr(w http.ResponseWriter, msg string) {
	_, err := fmt.Fprintf(w, "%s", makeRes(-1, msg, []gozi{}))
	if err != nil {
		log.Fatal(err)
	}
}
func writeRes(w http.ResponseWriter, data []gozi) {
	_, err := fmt.Fprintf(w, "%s", makeRes(0, "OK", data))
	if err != nil {
		log.Fatal(err)
	}
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
		err := r.ParseForm()
		if err != nil {
			writeResErr(w, err.Error())
			return
		}
		f := r.Form
		if !f.Has("x1") {
			writeResErr(w, "no x1")
			return
		}
		x1, err := strconv.Atoi(f.Get("x1"))
		if err != nil {
			writeResErr(w, "x1 not int")
			return
		}
		if !f.Has("x2") {
			writeResErr(w, "no x2")
			return
		}
		x2, err := strconv.Atoi(f.Get("x2"))
		if err != nil {
			writeResErr(w, "x2 should be int")
			return
		}
		if !f.Has("y1") {
			writeResErr(w, "no y1")
			return
		}
		y1, err := strconv.Atoi(f.Get("y1"))
		if err != nil {
			writeResErr(w, "y1 should be int")
			return
		}
		if !f.Has("y2") {
			writeResErr(w, "no y2")
			return
		}
		y2, err := strconv.Atoi(f.Get("y2"))
		if err != nil {
			writeResErr(w, "y2 should be int")
			return
		}
		if !(x1 < x2) {
			writeResErr(w, "x1<x2")
			return
		}
		if !(y1 < y2) {
			writeResErr(w, "y1<y2")
			return
		}
		a := getAll(db, x1, y1, x2, y2)
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
			writeResErr(w, err.Error())
			return
		}
		formData := gozi{}
		json.NewDecoder(r.Body).Decode(&formData)
		tx, err := db.Begin()
		if err != nil {
			writeResErr(w, err.Error())
			return
		}
		err = insertDoDB(tx, formData)
		if err != nil {
			tx.Rollback()
			log.Printf("%s\n", err)
			writeResErr(w, err.Error())
			return
		}
		err = tx.Commit()
		if err != nil {
			writeResErr(w, err.Error())
			return
		}
		// a := getAll(db, -1000, 1000, -1000, 1000)
		writeRes(w, []gozi{})
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
