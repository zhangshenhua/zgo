how to test
-----------

    # install go first
    go mod init zgo
    go mod tidy # maybe you can skip this
    go build 
    ./zgo -dbfile zi.db -port 8081

api
---

2. /doit

post a json {x:1,y:1,uid:1}

3. /getall?x1=1&x2=2&y1=1&y2=2

get all zi in a rect


server list
-----------
http://124.221.142.162:8081
