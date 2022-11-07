BEGIN;
    CREATE TEMP TABLE I(x, y, uid);
    CREATE TEMP TABLE D(x, y);

    INSERT INTO I SELECT x,y,uid FROM positions_need_insert;
    INSERT INTO D SELECT x,y FROM positions_need_delete;


    insert INTO ZI (x, y, uid) 
    SELECT x, y, uid from I;

    DELETE from ZI
    WHERE (ZI.x, ZI.y) in (
        SELECT x, y FROM D
    );
    DROP TABLE I;
    DROP TABLE D;
COMMIT;