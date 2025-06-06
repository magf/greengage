-- Tests for MPP-21090
set intervalstyle='postgres';
set datestyle='ISO, MDY';

create schema qp_dropped_cols;
set search_path='qp_dropped_cols';

-- TEST
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_char VALUES('g','g','a','g',0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_char DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_char VALUES('g','g','b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_char SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_char SELECT 'a', 'a','c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_char ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_char SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_char ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_char WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_decimal;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_decimal VALUES(2.00,2.00,'a',2.00,0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_decimal DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_decimal VALUES(2.00,2.00,'b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_decimal SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_decimal SELECT 1.00, 1.00,'c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_decimal ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_decimal SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_decimal WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_int4;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_int4 VALUES(20000000,20000000,'a',20000000,0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_int4 DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_int4 VALUES(20000000,20000000,'b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_int4 SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_int4 SELECT 10000000, 10000000,'c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int4 ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_int4 SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_int4 WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_int8;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_int8 VALUES(200000000000000000,200000000000000000,'a',200000000000000000,0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_int8 DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_int8 VALUES(200000000000000000,200000000000000000,'b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_int8 SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_int8 SELECT 1000000000000000000, 1000000000000000000,'c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int8 ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_int8 SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_int8 WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_interval;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_interval VALUES('10 secs','10 secs','a','10 secs',0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_interval DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_interval VALUES('10 secs','10 secs','b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_interval SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_interval SELECT '11 hours', '11 hours','c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_interval ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_interval SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_interval WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_changedistpolicy_dml_pttab_numeric;
CREATE TABLE mpp21090_changedistpolicy_dml_pttab_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) DISTRIBUTED BY (col1) PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));


INSERT INTO mpp21090_changedistpolicy_dml_pttab_numeric VALUES(2.000000,2.000000,'a',2.000000,0);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_numeric DROP COLUMN col4;

INSERT INTO mpp21090_changedistpolicy_dml_pttab_numeric VALUES(2.000000,2.000000,'b',1);
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_changedistpolicy_dml_pttab_numeric SET DISTRIBUTED BY (col3);

INSERT INTO mpp21090_changedistpolicy_dml_pttab_numeric SELECT 1.000000, 1.000000,'c', 2;
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_numeric ORDER BY 1,2,3;

UPDATE mpp21090_changedistpolicy_dml_pttab_numeric SET col3 ='c' WHERE col3 ='b';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_changedistpolicy_dml_pttab_numeric WHERE col3 ='c';
SELECT * FROM mpp21090_changedistpolicy_dml_pttab_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_char;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_char VALUES('x','x','a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_char DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_char SELECT 'z','z','b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_char ADD COLUMN col5 char;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_char SELECT 'x','x','c','x';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_char SET col1 = '-' WHERE col2 = 'z' AND col1 = 'z';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_char SET col2 = '-' WHERE col2 = 'z' AND col1 = '-';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_char WHERE col2 = '-';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_decimal;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_decimal DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_decimal SELECT 35.00,35.00,'b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_decimal ADD COLUMN col5 decimal;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_decimal SELECT 2.00,2.00,'c',2.00;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_decimal SET col1 = 1.00 WHERE col2 = 35.00 AND col1 = 35.00;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col1 = 1.00;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_int4;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_int4 DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int4 SELECT 35000000,35000000,'b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_int4 ADD COLUMN col5 int4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int4 SELECT 20000000,20000000,'c',20000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_int4 SET col1 = 10000000 WHERE col2 = 35000000 AND col1 = 35000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col1 = 10000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_int8;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_int8 DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int8 SELECT 3500000000000000000,3500000000000000000,'b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_int8 ADD COLUMN col5 int8;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_int8 SELECT 2000000000000000000,2000000000000000000,'c',2000000000000000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_int8 SET col1 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 1000000000000000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_interval;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_interval VALUES('1 hour','1 hour','a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_interval DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_interval SELECT '14 hours','14 hours','b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_interval ADD COLUMN col5 interval;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_interval SELECT '1 hour','1 hour','c','1 hour';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_interval SET col1 = '12 hours' WHERE col2 = '14 hours' AND col1 = '14 hours';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_interval SET col2 = '12 hours' WHERE col2 = '14 hours' AND col1 = '12 hours';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_numeric;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_numeric DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_numeric SELECT 35.000000,35.000000,'b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_numeric ADD COLUMN col5 numeric;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_numeric SELECT 2.000000,2.000000,'c',2.000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_numeric SET col1 = 1.000000 WHERE col2 = 35.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_defpt_dropcol_addcol_dml_text;
CREATE TABLE mpp21090_defpt_dropcol_addcol_dml_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0);

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_text DROP COLUMN col4;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_text SELECT 'xyz','xyz','b';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_defpt_dropcol_addcol_dml_text ADD COLUMN col5 text;

INSERT INTO mpp21090_defpt_dropcol_addcol_dml_text SELECT 'abcdefghijklmnop','abcdefghijklmnop','c','abcdefghijklmnop';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

UPDATE mpp21090_defpt_dropcol_addcol_dml_text SET col1 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'xyz';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_defpt_dropcol_addcol_dml_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'qrstuvwxyz';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

DELETE FROM mpp21090_defpt_dropcol_addcol_dml_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_defpt_dropcol_addcol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS dropped_col_tab;
CREATE TABLE dropped_col_tab(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO dropped_col_tab VALUES(0,0.00,'a','2014-01-01',0);
SELECT * FROM dropped_col_tab ORDER BY 1,2,3;

ALTER TABLE dropped_col_tab DROP COLUMN col1;
ALTER TABLE dropped_col_tab DROP COLUMN col2;
ALTER TABLE dropped_col_tab DROP COLUMN col3;
ALTER TABLE dropped_col_tab DROP COLUMN col4;
ALTER TABLE dropped_col_tab DROP COLUMN col5;

INSERT INTO dropped_col_tab SELECT 1;
SELECT * FROM dropped_col_tab;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_char;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_char VALUES('x','x','a','x');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_char DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_char VALUES('x','x','b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_char ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_char VALUES('x','x','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_char SPLIT DEFAULT PARTITION at ('d') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_char SELECT 'a', 'a','e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_char SET col2 = 'z' WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_decimal;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_decimal VALUES(2.00,2.00,'a',2.00);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_decimal DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_decimal VALUES(2.00,2.00,'b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_decimal ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_decimal VALUES(2.00,2.00,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_decimal SPLIT DEFAULT PARTITION at (5.00) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_decimal SELECT 1.00, 1.00,'e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_decimal SET col2 = 35.00 WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_int4;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int4 VALUES(20000000,20000000,'a',20000000);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int4 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int4 VALUES(20000000,20000000,'b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int4 ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int4 VALUES(20000000,20000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int4 SPLIT DEFAULT PARTITION at (50000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int4 SELECT 10000000, 10000000,'e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_int4 SET col1 = 35000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_int4 SET col2 = 35000000 WHERE col2 = 10000000 AND col1 = 35000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_int8;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int8 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int8 ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_int8 SPLIT DEFAULT PARTITION at (500000000000000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_int8 SELECT 100000000000000000, 100000000000000000,'e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_int8 SET col2 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_interval;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','a','1 hour');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval VALUES('1 hour','1 hour','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_interval SPLIT DEFAULT PARTITION at ('30 secs') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_interval SELECT '1 sec', '1 sec','e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_interval SET col2 = '14 hours' WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitdefpt_dml_numeric;
CREATE TABLE mpp21090_dropcol_addcol_splitdefpt_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_numeric VALUES(2.000000,2.000000,'a',2.000000);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_numeric DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_numeric VALUES(2.000000,2.000000,'b');
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_numeric ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_numeric VALUES(2.000000,2.000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitdefpt_dml_numeric SPLIT DEFAULT PARTITION at (5.000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_addcol_splitdefpt_dml_numeric SELECT 1.000000, 1.000000,'e', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitdefpt_dml_numeric SET col2 = 35.000000 WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitdefpt_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_char;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_char VALUES('x','x','a','x');
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_char ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_char VALUES('x','x','b','x',0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_char DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_char VALUES('x','x','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_char SPLIT PARTITION partone at ('d') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_char SELECT 'a', 'a','d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_char SET col2 ='x'  WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_decimal;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_decimal VALUES(2.00,2.00,'a',2.00);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_decimal ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_decimal VALUES(2.00,2.00,'b',2.00,0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_decimal DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_decimal VALUES(2.00,2.00,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_decimal SPLIT PARTITION partone at (5.00) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_decimal SELECT 1.00, 1.00,'d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_decimal SET col2 =2.00  WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_int4;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int4 VALUES(20000000,20000000,'a',20000000);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int4 ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int4 VALUES(20000000,20000000,'b',20000000,0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int4 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int4 VALUES(20000000,20000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int4 SPLIT PARTITION partone at (50000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int4 SELECT 10000000, 10000000,'d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_int4 SET col1 = 35000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_int4 SET col2 =20000000  WHERE col2 = 10000000 AND col1 = 35000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_int8;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int8 ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'b',2000000000000000000,0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int8 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_int8 SPLIT PARTITION partone at (500000000000000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_int8 SELECT 100000000000000000, 100000000000000000,'d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_int8 SET col2 =2000000000000000000  WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_interval;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_interval VALUES('1 hour','1 hour','a','1 hour');
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_interval ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_interval VALUES('1 hour','1 hour','b','1 hour',0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_interval DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_interval VALUES('1 hour','1 hour','c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_interval SPLIT PARTITION partone at ('30 secs') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_interval SELECT '1 sec', '1 sec','d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_interval SET col2 ='1 hour'  WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_addcol_splitpt_dml_numeric;
CREATE TABLE mpp21090_dropcol_addcol_splitpt_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_numeric VALUES(2.000000,2.000000,'a',2.000000);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_numeric ADD COLUMN col5 int DEFAULT 10;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_numeric VALUES(2.000000,2.000000,'b',2.000000,0);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_numeric DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_numeric VALUES(2.000000,2.000000,'c',1);
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_addcol_splitpt_dml_numeric SPLIT PARTITION partone at (5.000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_addcol_splitpt_dml_numeric SELECT 1.000000, 1.000000,'d', 1;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_addcol_splitpt_dml_numeric SET col2 =2.000000  WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_addcol_splitpt_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_addcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 boolean,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a',True,1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4=False WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 char,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a','z',1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4='-' WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 decimal,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a',2.00,1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4=1.00 WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 int4,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a',2000000000,1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4=1000000000 WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 int8,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a',2000000000000000000,1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4=1000000000000000000 WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 interval,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a','1 day',1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4='1 hour' WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 numeric,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a',2.000000,1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4=1.000000 WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS oidtab;
CREATE TABLE oidtab(
col1 serial,
col2 decimal,
col3 char,
col4 text,
col5 int
) WITH OIDS DISTRIBUTED by(col4);

ALTER TABLE oidtab DROP COLUMN col2;

INSERT INTO oidtab(col3,col4,col5) SELECT 'a','abcdefghijklmnop',1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

DROP TABLE IF EXISTS tempoid;
CREATE TABLE tempoid as SELECT oid,col1,col3,col4,col5 FROM oidtab ORDER BY 1;

UPDATE oidtab SET col4='qrstuvwxyz' WHERE col3 = 'a' AND col5 = 1;
SELECT * FROM oidtab ORDER BY 1,2,3,4;

SELECT * FROM ((SELECT COUNT(*) FROM oidtab) UNION (SELECT COUNT(*) FROM tempoid, oidtab WHERE tempoid.oid = oidtab.oid AND tempoid.col5 = oidtab.col5))foo;


-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_char;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_char VALUES('x','x','a','x');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_char DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_char VALUES('x','x','b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_char SPLIT DEFAULT PARTITION at ('d') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_char SELECT 'a', 'a','e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_char ADD COLUMN col5 char DEFAULT 'x';

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_char VALUES('x','x','c','x');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_char SET col2 = 'z' WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_decimal;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'a',2.00);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SPLIT DEFAULT PARTITION at (5.00) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal SELECT 1.00, 1.00,'e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_decimal ADD COLUMN col5 decimal DEFAULT 2.00;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_decimal VALUES(2.00,2.00,'c',2.00);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_decimal SET col2 = 35.00 WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_int4;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int4 VALUES(20000000,20000000,'a',20000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int4 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int4 VALUES(20000000,20000000,'b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int4 SPLIT DEFAULT PARTITION at (50000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int4 SELECT 10000000, 10000000,'e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int4 ADD COLUMN col5 int4 DEFAULT 20000000;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int4 VALUES(20000000,20000000,'c',20000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_int4 SET col1 = 35000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_int4 SET col2 = 35000000 WHERE col2 = 10000000 AND col1 = 35000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_int8;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int8 DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int8 SPLIT DEFAULT PARTITION at (500000000000000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int8 SELECT 100000000000000000, 100000000000000000,'e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_int8 ADD COLUMN col5 int8 DEFAULT 2000000000000000000;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'c',2000000000000000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_int8 SET col2 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_interval;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_interval VALUES('1 hour','1 hour','a','1 hour');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_interval DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_interval VALUES('1 hour','1 hour','b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_interval SPLIT DEFAULT PARTITION at ('30 secs') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_interval SELECT '1 sec', '1 sec','e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_interval ADD COLUMN col5 interval DEFAULT '1 hour';

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_interval VALUES('1 hour','1 hour','c','1 hour');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_interval SET col2 = '14 hours' WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdefpt_addcol_dml_numeric;
CREATE TABLE mpp21090_dropcol_splitdefpt_addcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_numeric VALUES(2.000000,2.000000,'a',2.000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_numeric DROP COLUMN col4;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_numeric VALUES(2.000000,2.000000,'b');
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_numeric SPLIT DEFAULT PARTITION at (5.000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_numeric SELECT 1.000000, 1.000000,'e';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_dropcol_splitdefpt_addcol_dml_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;

INSERT INTO mpp21090_dropcol_splitdefpt_addcol_dml_numeric VALUES(2.000000,2.000000,'c',2.000000);
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3,4;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdefpt_addcol_dml_numeric SET col2 = 35.000000 WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdefpt_addcol_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_char;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_char VALUES('x','x','a','x',0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_char DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_char SPLIT DEFAULT PARTITION at ('d') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_char SELECT 'a', 'a','b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_char SET col2 = 'z' WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_decimal;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_decimal VALUES(2.00,2.00,'a',2.00,0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_decimal DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_decimal SPLIT DEFAULT PARTITION at (5.00) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_decimal SELECT 1.00, 1.00,'b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_decimal SET col2 = 35.00 WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_int4;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_int4 VALUES(20000000,20000000,'a',20000000,0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_int4 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_int4 SPLIT DEFAULT PARTITION at (50000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_int4 SELECT 10000000, 10000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_int4 SET col1 = 35000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_int4 SET col2 = 35000000 WHERE col2 = 10000000 AND col1 = 35000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_int8;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000,0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_int8 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_int8 SPLIT DEFAULT PARTITION at (500000000000000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_int8 SELECT 100000000000000000, 100000000000000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_int8 SET col2 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_interval;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_interval VALUES('1 hour','1 hour','a','1 hour',0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_interval DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_interval SPLIT DEFAULT PARTITION at ('30 secs') into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_interval SELECT '1 sec', '1 sec','b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_interval SET col2 = '14 hours' WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitdfpt_dml_numeric;
CREATE TABLE mpp21090_dropcol_splitdfpt_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)
(
default partition def
);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_numeric VALUES(2.000000,2.000000,'a',2.000000,0);
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_numeric DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitdfpt_dml_numeric SPLIT DEFAULT PARTITION at (5.000000) into (partition partsplitone,partition def);

INSERT INTO mpp21090_dropcol_splitdfpt_dml_numeric SELECT 1.000000, 1.000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitdfpt_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitdfpt_dml_numeric SET col2 = 35.000000 WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitdfpt_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitdfpt_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_char;
CREATE TABLE mpp21090_dropcol_splitpt_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_dropcol_splitpt_dml_char VALUES('x','x','a','x',0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_char DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_char SPLIT PARTITION partone at ('d') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_char SELECT 'a', 'a','b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_splitpt_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_char SET col2 ='x'  WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_splitpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_decimal;
CREATE TABLE mpp21090_dropcol_splitpt_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_dropcol_splitpt_dml_decimal VALUES(2.00,2.00,'a',2.00,0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_decimal DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_decimal SPLIT PARTITION partone at (5.00) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_decimal SELECT 1.00, 1.00,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_decimal SET col2 =2.00  WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_splitpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_int4;
CREATE TABLE mpp21090_dropcol_splitpt_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_dropcol_splitpt_dml_int4 VALUES(20000000,20000000,'a',20000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_int4 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_int4 SPLIT PARTITION partone at (50000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_int4 SELECT 10000000, 10000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_int4 SET col1 = 35000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_int4 SET col2 =20000000  WHERE col2 = 10000000 AND col1 = 35000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_int8;
CREATE TABLE mpp21090_dropcol_splitpt_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_dropcol_splitpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_int8 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_int8 SPLIT PARTITION partone at (500000000000000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_int8 SELECT 100000000000000000, 100000000000000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_int8 SET col2 =2000000000000000000  WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_interval;
CREATE TABLE mpp21090_dropcol_splitpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_dropcol_splitpt_dml_interval VALUES('1 hour','1 hour','a','1 hour',0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_interval DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_interval SPLIT PARTITION partone at ('30 secs') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_interval SELECT '1 sec', '1 sec','b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_splitpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_interval SET col2 ='1 hour'  WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_splitpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_dml_numeric;
CREATE TABLE mpp21090_dropcol_splitpt_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_dropcol_splitpt_dml_numeric VALUES(2.000000,2.000000,'a',2.000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_numeric DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_dml_numeric SPLIT PARTITION partone at (5.000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_dml_numeric SELECT 1.000000, 1.000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_dml_numeric SET col2 =2.000000  WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_splitpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_char;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_char;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_char on mpp21090_dropcol_splitpt_idx_dml_char(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_char VALUES('g','g','a','g',0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_char DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_char SPLIT PARTITION partone at ('d') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_char SELECT 'a', 'a','b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_char SET col1 = 'z' WHERE col2 = 'a' AND col1 = 'a';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_char SET col2 ='g'  WHERE col2 = 'a' AND col1 = 'z';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_char WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_char ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_decimal;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_decimal;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_decimal on mpp21090_dropcol_splitpt_idx_dml_decimal(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_decimal VALUES(2.00,2.00,'a',2.00,0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_decimal DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_decimal SPLIT PARTITION partone at (5.00) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_decimal SELECT 1.00, 1.00,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_decimal SET col1 = 35.00 WHERE col2 = 1.00 AND col1 = 1.00;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_decimal SET col2 =2.00  WHERE col2 = 1.00 AND col1 = 35.00;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_decimal ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_int4;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_int4;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_int4 on mpp21090_dropcol_splitpt_idx_dml_int4(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_int4 VALUES(20000000,20000000,'a',20000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_int4 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_int4 SPLIT PARTITION partone at (50000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_int4 SELECT 10000000, 10000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_int4 SET col1 = 350000000 WHERE col2 = 10000000 AND col1 = 10000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_int4 SET col2 =20000000  WHERE col2 = 10000000 AND col1 = 350000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int4 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_int8;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_int8;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_int8 on mpp21090_dropcol_splitpt_idx_dml_int8(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_int8 VALUES(200000000000000000,200000000000000000,'a',200000000000000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_int8 DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_int8 SPLIT PARTITION partone at (500000000000000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_int8 SELECT 100000000000000000, 100000000000000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_int8 SET col1 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col1 = 100000000000000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_int8 SET col2 =200000000000000000  WHERE col2 = 100000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_int8 ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_interval;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_interval;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_interval on mpp21090_dropcol_splitpt_idx_dml_interval(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_interval VALUES('10 secs','10 secs','a','10 secs',0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_interval DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_interval SPLIT PARTITION partone at ('30 secs') into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_interval SELECT '1 sec', '1 sec','b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_interval SET col1 = '14 hours' WHERE col2 = '1 sec' AND col1 = '1 sec';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_interval SET col2 ='10 secs'  WHERE col2 = '1 sec' AND col1 = '14 hours';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_interval ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_dropcol_splitpt_idx_dml_numeric;
CREATE TABLE mpp21090_dropcol_splitpt_idx_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

DROP INDEX IF EXISTS mpp21090_dropcol_splitpt_idx_dml_idx_numeric;
CREATE INDEX mpp21090_dropcol_splitpt_idx_dml_idx_numeric on mpp21090_dropcol_splitpt_idx_dml_numeric(col2);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_numeric VALUES(2.000000,2.000000,'a',2.000000,0);
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_numeric DROP COLUMN col4;

ALTER TABLE mpp21090_dropcol_splitpt_idx_dml_numeric SPLIT PARTITION partone at (5.000000) into (partition partsplitone,partition partsplitwo);

INSERT INTO mpp21090_dropcol_splitpt_idx_dml_numeric SELECT 1.000000, 1.000000,'b', 1;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_dropcol_splitpt_idx_dml_numeric SET col1 = 35.000000 WHERE col2 = 1.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_dropcol_splitpt_idx_dml_numeric SET col2 =2.000000  WHERE col2 = 1.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_dropcol_splitpt_idx_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_dropcol_splitpt_idx_dml_numeric ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_boolean;
CREATE TABLE mpp21090_drop_distcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_boolean;
CREATE TABLE mpp21090_drop_distcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_boolean;
CREATE TABLE mpp21090_drop_distcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_char;
CREATE TABLE mpp21090_drop_distcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_char;
CREATE TABLE mpp21090_drop_distcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_char;
CREATE TABLE mpp21090_drop_distcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_decimal;
CREATE TABLE mpp21090_drop_distcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_decimal;
CREATE TABLE mpp21090_drop_distcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_decimal;
CREATE TABLE mpp21090_drop_distcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int4;
CREATE TABLE mpp21090_drop_distcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int4;
CREATE TABLE mpp21090_drop_distcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int4;
CREATE TABLE mpp21090_drop_distcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int8;
CREATE TABLE mpp21090_drop_distcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int8;
CREATE TABLE mpp21090_drop_distcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_int8;
CREATE TABLE mpp21090_drop_distcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_interval;
CREATE TABLE mpp21090_drop_distcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_interval;
CREATE TABLE mpp21090_drop_distcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_interval;
CREATE TABLE mpp21090_drop_distcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_numeric;
CREATE TABLE mpp21090_drop_distcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_numeric;
CREATE TABLE mpp21090_drop_distcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_numeric;
CREATE TABLE mpp21090_drop_distcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_text;
CREATE TABLE mpp21090_drop_distcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_text;
CREATE TABLE mpp21090_drop_distcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_distcol_dml_text;
CREATE TABLE mpp21090_drop_distcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
) distributed by (col1);
INSERT INTO mpp21090_drop_distcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_distcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_distcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_distcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_distcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_distcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_boolean;
CREATE TABLE mpp21090_drop_firstcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_boolean;
CREATE TABLE mpp21090_drop_firstcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_boolean;
CREATE TABLE mpp21090_drop_firstcol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_boolean DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_boolean SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_char;
CREATE TABLE mpp21090_drop_firstcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_char;
CREATE TABLE mpp21090_drop_firstcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_char;
CREATE TABLE mpp21090_drop_firstcol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_char DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_char SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_decimal;
CREATE TABLE mpp21090_drop_firstcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_decimal;
CREATE TABLE mpp21090_drop_firstcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_decimal;
CREATE TABLE mpp21090_drop_firstcol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_decimal DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_decimal SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int4;
CREATE TABLE mpp21090_drop_firstcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int4;
CREATE TABLE mpp21090_drop_firstcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int4;
CREATE TABLE mpp21090_drop_firstcol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int4 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int4 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int8;
CREATE TABLE mpp21090_drop_firstcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int8;
CREATE TABLE mpp21090_drop_firstcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_int8;
CREATE TABLE mpp21090_drop_firstcol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_int8 DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_int8 SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_interval;
CREATE TABLE mpp21090_drop_firstcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_interval;
CREATE TABLE mpp21090_drop_firstcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_interval;
CREATE TABLE mpp21090_drop_firstcol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_interval DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_interval SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_numeric;
CREATE TABLE mpp21090_drop_firstcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_numeric;
CREATE TABLE mpp21090_drop_firstcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_numeric;
CREATE TABLE mpp21090_drop_firstcol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_numeric DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_numeric SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_text;
CREATE TABLE mpp21090_drop_firstcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_text;
CREATE TABLE mpp21090_drop_firstcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_firstcol_dml_text;
CREATE TABLE mpp21090_drop_firstcol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_firstcol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_firstcol_dml_text DROP COLUMN col1;
INSERT INTO mpp21090_drop_firstcol_dml_text SELECT 1.00,'b','2014-01-02',1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_firstcol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_firstcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_firstcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_boolean;
CREATE TABLE mpp21090_drop_lastcol_dml_boolean(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 boolean
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_boolean VALUES(0,0.00,'a','2014-01-01',True);
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_boolean DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_boolean;
CREATE TABLE mpp21090_drop_lastcol_dml_boolean(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 boolean
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_boolean VALUES(0,0.00,'a','2014-01-01',True);
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_boolean DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_boolean;
CREATE TABLE mpp21090_drop_lastcol_dml_boolean(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 boolean
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_boolean VALUES(0,0.00,'a','2014-01-01',True);
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_boolean DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_boolean ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_char;
CREATE TABLE mpp21090_drop_lastcol_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_char VALUES(0,0.00,'a','2014-01-01','z');
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_char DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_char;
CREATE TABLE mpp21090_drop_lastcol_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_char VALUES(0,0.00,'a','2014-01-01','z');
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_char DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_char;
CREATE TABLE mpp21090_drop_lastcol_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_char VALUES(0,0.00,'a','2014-01-01','z');
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_char DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_decimal DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_decimal DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_decimal DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int4 VALUES(0,0.00,'a','2014-01-01',2000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int4 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int4 VALUES(0,0.00,'a','2014-01-01',2000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int4 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int4 VALUES(0,0.00,'a','2014-01-01',2000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int4 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int8 VALUES(0,0.00,'a','2014-01-01',2000000000000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int8 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int8 VALUES(0,0.00,'a','2014-01-01',2000000000000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int8 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_int8 VALUES(0,0.00,'a','2014-01-01',2000000000000000000);
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_int8 DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_interval VALUES(0,0.00,'a','2014-01-01','1 day');
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_interval DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_interval VALUES(0,0.00,'a','2014-01-01','1 day');
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_interval DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_interval VALUES(0,0.00,'a','2014-01-01','1 day');
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_interval DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_numeric DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_numeric DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_numeric DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_text;
CREATE TABLE mpp21090_drop_lastcol_dml_text(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 text
) with (appendonly= true)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_text VALUES(0,0.00,'a','2014-01-01','abcdefghijklmnop');
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_text DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_text SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_text;
CREATE TABLE mpp21090_drop_lastcol_dml_text(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 text
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_text VALUES(0,0.00,'a','2014-01-01','abcdefghijklmnop');
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_text DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_text SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_dml_text;
CREATE TABLE mpp21090_drop_lastcol_dml_text(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 text
) DISTRIBUTED by(col3);
INSERT INTO mpp21090_drop_lastcol_dml_text VALUES(0,0.00,'a','2014-01-01','abcdefghijklmnop');
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_lastcol_dml_text DROP COLUMN col5;
INSERT INTO mpp21090_drop_lastcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_lastcol_dml_text SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;
DELETE FROM mpp21090_drop_lastcol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_dml_text ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_char;
CREATE TABLE mpp21090_drop_lastcol_index_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_char;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_char on mpp21090_drop_lastcol_index_dml_char(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_char VALUES(0,0.00,'a','2014-01-01','g');
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_char DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_char;
CREATE TABLE mpp21090_drop_lastcol_index_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_char;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_char on mpp21090_drop_lastcol_index_dml_char(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_char VALUES(0,0.00,'a','2014-01-01','g');
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_char DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_char;
CREATE TABLE mpp21090_drop_lastcol_index_dml_char(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 char
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_char;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_char on mpp21090_drop_lastcol_index_dml_char(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_char VALUES(0,0.00,'a','2014-01-01','g');
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_char DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_char SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_index_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_decimal;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_decimal on mpp21090_drop_lastcol_index_dml_decimal(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_decimal DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_index_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_decimal;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_decimal on mpp21090_drop_lastcol_index_dml_decimal(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_decimal DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_decimal;
CREATE TABLE mpp21090_drop_lastcol_index_dml_decimal(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 decimal
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_decimal;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_decimal on mpp21090_drop_lastcol_index_dml_decimal(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal VALUES(0,0.00,'a','2014-01-01',2.00);
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_decimal DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_decimal SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int4;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int4 on mpp21090_drop_lastcol_index_dml_int4(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 VALUES(0,0.00,'a','2014-01-01',20000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int4 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int4;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int4 on mpp21090_drop_lastcol_index_dml_int4(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 VALUES(0,0.00,'a','2014-01-01',20000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int4 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int4;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int4(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int4
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int4;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int4 on mpp21090_drop_lastcol_index_dml_int4(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 VALUES(0,0.00,'a','2014-01-01',20000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int4 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int4 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int8;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int8 on mpp21090_drop_lastcol_index_dml_int8(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 VALUES(0,0.00,'a','2014-01-01',200000000000000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int8 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int8;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int8 on mpp21090_drop_lastcol_index_dml_int8(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 VALUES(0,0.00,'a','2014-01-01',200000000000000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int8 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_int8;
CREATE TABLE mpp21090_drop_lastcol_index_dml_int8(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 int8
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_int8;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_int8 on mpp21090_drop_lastcol_index_dml_int8(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 VALUES(0,0.00,'a','2014-01-01',200000000000000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_int8 DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_int8 SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_index_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_interval;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_interval on mpp21090_drop_lastcol_index_dml_interval(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_interval VALUES(0,0.00,'a','2014-01-01','10 secs');
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_interval DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_index_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_interval;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_interval on mpp21090_drop_lastcol_index_dml_interval(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_interval VALUES(0,0.00,'a','2014-01-01','10 secs');
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_interval DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_interval;
CREATE TABLE mpp21090_drop_lastcol_index_dml_interval(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 interval
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_interval;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_interval on mpp21090_drop_lastcol_index_dml_interval(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_interval VALUES(0,0.00,'a','2014-01-01','10 secs');
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_interval DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_interval SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_index_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) with (appendonly= true)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_numeric;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_numeric on mpp21090_drop_lastcol_index_dml_numeric(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_numeric DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_index_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_numeric;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_numeric on mpp21090_drop_lastcol_index_dml_numeric(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_numeric DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_lastcol_index_dml_numeric;
CREATE TABLE mpp21090_drop_lastcol_index_dml_numeric(
col1 int,
col2 decimal,
col3 char,
col4 date,
col5 numeric
) DISTRIBUTED by(col3);

DROP INDEX IF EXISTS mpp21090_drop_lastcol_index_dml_idx_numeric;
CREATE INDEX mpp21090_drop_lastcol_index_dml_idx_numeric on mpp21090_drop_lastcol_index_dml_numeric(col3);

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric VALUES(0,0.00,'a','2014-01-01',2.000000);
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_drop_lastcol_index_dml_numeric DROP COLUMN col5;

INSERT INTO mpp21090_drop_lastcol_index_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

UPDATE mpp21090_drop_lastcol_index_dml_numeric SET col3='c' WHERE col3 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;

DELETE FROM mpp21090_drop_lastcol_index_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_lastcol_index_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_boolean;
CREATE TABLE mpp21090_drop_midcol_dml_boolean
(
col1 int,
col2 decimal,
col3 boolean,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_boolean VALUES(0,0.00,True,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_boolean DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_boolean SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_boolean;
CREATE TABLE mpp21090_drop_midcol_dml_boolean
(
col1 int,
col2 decimal,
col3 boolean,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_boolean VALUES(0,0.00,True,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_boolean DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_boolean SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_boolean;
CREATE TABLE mpp21090_drop_midcol_dml_boolean
(
col1 int,
col2 decimal,
col3 boolean,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_boolean VALUES(0,0.00,True,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_boolean DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_boolean SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_boolean SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_boolean ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_char;
CREATE TABLE mpp21090_drop_midcol_dml_char
(
col1 int,
col2 decimal,
col3 char,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_char VALUES(0,0.00,'z','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_char DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_char SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_char;
CREATE TABLE mpp21090_drop_midcol_dml_char
(
col1 int,
col2 decimal,
col3 char,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_char VALUES(0,0.00,'z','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_char DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_char SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_char;
CREATE TABLE mpp21090_drop_midcol_dml_char
(
col1 int,
col2 decimal,
col3 char,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_char VALUES(0,0.00,'z','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_char DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_char SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_char SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_char ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_decimal;
CREATE TABLE mpp21090_drop_midcol_dml_decimal
(
col1 int,
col2 decimal,
col3 decimal,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_decimal VALUES(0,0.00,2.00,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_decimal DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_decimal SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_decimal;
CREATE TABLE mpp21090_drop_midcol_dml_decimal
(
col1 int,
col2 decimal,
col3 decimal,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_decimal VALUES(0,0.00,2.00,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_decimal DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_decimal SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_decimal;
CREATE TABLE mpp21090_drop_midcol_dml_decimal
(
col1 int,
col2 decimal,
col3 decimal,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_decimal VALUES(0,0.00,2.00,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_decimal DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_decimal SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_decimal SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_decimal ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int4;
CREATE TABLE mpp21090_drop_midcol_dml_int4
(
col1 int,
col2 decimal,
col3 int4,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int4 VALUES(0,0.00,2000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int4 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int4 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int4;
CREATE TABLE mpp21090_drop_midcol_dml_int4
(
col1 int,
col2 decimal,
col3 int4,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int4 VALUES(0,0.00,2000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int4 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int4 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int4;
CREATE TABLE mpp21090_drop_midcol_dml_int4
(
col1 int,
col2 decimal,
col3 int4,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int4 VALUES(0,0.00,2000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int4 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int4 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int4 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int4 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int8;
CREATE TABLE mpp21090_drop_midcol_dml_int8
(
col1 int,
col2 decimal,
col3 int8,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int8 VALUES(0,0.00,2000000000000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int8 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int8 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int8;
CREATE TABLE mpp21090_drop_midcol_dml_int8
(
col1 int,
col2 decimal,
col3 int8,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int8 VALUES(0,0.00,2000000000000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int8 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int8 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_int8;
CREATE TABLE mpp21090_drop_midcol_dml_int8
(
col1 int,
col2 decimal,
col3 int8,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_int8 VALUES(0,0.00,2000000000000000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_int8 DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_int8 SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_int8 SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_int8 ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_interval;
CREATE TABLE mpp21090_drop_midcol_dml_interval
(
col1 int,
col2 decimal,
col3 interval,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_interval VALUES(0,0.00,'1 day','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_interval DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_interval SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_interval;
CREATE TABLE mpp21090_drop_midcol_dml_interval
(
col1 int,
col2 decimal,
col3 interval,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_interval VALUES(0,0.00,'1 day','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_interval DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_interval SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_interval;
CREATE TABLE mpp21090_drop_midcol_dml_interval
(
col1 int,
col2 decimal,
col3 interval,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_interval VALUES(0,0.00,'1 day','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_interval DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_interval SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_interval SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_interval ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_numeric;
CREATE TABLE mpp21090_drop_midcol_dml_numeric
(
col1 int,
col2 decimal,
col3 numeric,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_numeric VALUES(0,0.00,2.000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_numeric DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_numeric SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_numeric;
CREATE TABLE mpp21090_drop_midcol_dml_numeric
(
col1 int,
col2 decimal,
col3 numeric,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_numeric VALUES(0,0.00,2.000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_numeric DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_numeric SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_numeric;
CREATE TABLE mpp21090_drop_midcol_dml_numeric
(
col1 int,
col2 decimal,
col3 numeric,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_numeric VALUES(0,0.00,2.000000,'a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_numeric DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_numeric SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_numeric SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_numeric ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_text;
CREATE TABLE mpp21090_drop_midcol_dml_text
(
col1 int,
col2 decimal,
col3 text,
col4 char,
col5 date
) with (appendonly= true)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_text VALUES(0,0.00,'abcdefghijklmnop','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_text DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_text SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_text;
CREATE TABLE mpp21090_drop_midcol_dml_text
(
col1 int,
col2 decimal,
col3 text,
col4 char,
col5 date
) with (appendonly= true, orientation= column)  DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_text VALUES(0,0.00,'abcdefghijklmnop','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_text DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_text SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_midcol_dml_text;
CREATE TABLE mpp21090_drop_midcol_dml_text
(
col1 int,
col2 decimal,
col3 text,
col4 char,
col5 date
) DISTRIBUTED by(col4);
INSERT INTO mpp21090_drop_midcol_dml_text VALUES(0,0.00,'abcdefghijklmnop','a','2014-01-01');
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_midcol_dml_text DROP COLUMN col3;
INSERT INTO mpp21090_drop_midcol_dml_text SELECT 1,1.00,'b','2014-01-02';
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;
UPDATE mpp21090_drop_midcol_dml_text SET col4='c' WHERE col4 = 'b' AND col1 = 1;
SELECT * FROM mpp21090_drop_midcol_dml_text ORDER BY 1,2,3,4;

-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_boolean;
CREATE TABLE mpp21090_drop_multicol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_boolean SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_boolean;
CREATE TABLE mpp21090_drop_multicol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_boolean SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_boolean;
CREATE TABLE mpp21090_drop_multicol_dml_boolean(
col1 boolean,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_boolean VALUES(True,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_boolean DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_boolean SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_boolean SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_boolean WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_boolean ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_char;
CREATE TABLE mpp21090_drop_multicol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_char SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_char;
CREATE TABLE mpp21090_drop_multicol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_char SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_char;
CREATE TABLE mpp21090_drop_multicol_dml_char(
col1 char,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_char VALUES('z',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_char DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_char SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_char SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_char WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_decimal;
CREATE TABLE mpp21090_drop_multicol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_decimal SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_decimal;
CREATE TABLE mpp21090_drop_multicol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_decimal SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_decimal;
CREATE TABLE mpp21090_drop_multicol_dml_decimal(
col1 decimal,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_decimal VALUES(2.00,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_decimal DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_decimal SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_decimal SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_decimal WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int4;
CREATE TABLE mpp21090_drop_multicol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int4 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int4;
CREATE TABLE mpp21090_drop_multicol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int4 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int4;
CREATE TABLE mpp21090_drop_multicol_dml_int4(
col1 int4,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int4 VALUES(2000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int4 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int4 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int4 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int4 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int8;
CREATE TABLE mpp21090_drop_multicol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int8 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int8;
CREATE TABLE mpp21090_drop_multicol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int8 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_int8;
CREATE TABLE mpp21090_drop_multicol_dml_int8(
col1 int8,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_int8 VALUES(2000000000000000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_int8 DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_int8 SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_int8 SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_int8 WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_interval;
CREATE TABLE mpp21090_drop_multicol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_interval SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_interval;
CREATE TABLE mpp21090_drop_multicol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_interval SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_interval;
CREATE TABLE mpp21090_drop_multicol_dml_interval(
col1 interval,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_interval VALUES('1 day',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_interval DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_interval SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_interval SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_interval WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_numeric;
CREATE TABLE mpp21090_drop_multicol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_numeric SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_numeric;
CREATE TABLE mpp21090_drop_multicol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_numeric SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_numeric;
CREATE TABLE mpp21090_drop_multicol_dml_numeric(
col1 numeric,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_numeric VALUES(2.000000,0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_numeric DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_numeric SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_numeric SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_numeric WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_text;
CREATE TABLE mpp21090_drop_multicol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_text SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_text;
CREATE TABLE mpp21090_drop_multicol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  with (appendonly= true, orientation= column)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_text SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_drop_multicol_dml_text;
CREATE TABLE mpp21090_drop_multicol_dml_text(
col1 text,
col2 decimal,
col3 char,
col4 date,
col5 int
)  DISTRIBUTED by (col3);
INSERT INTO mpp21090_drop_multicol_dml_text VALUES('abcdefghijklmnop',0.00,'a','2014-01-01',0);
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3,4;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col1;
ALTER TABLE mpp21090_drop_multicol_dml_text DROP COLUMN col4;
INSERT INTO mpp21090_drop_multicol_dml_text SELECT 1.00,'b',1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
UPDATE mpp21090_drop_multicol_dml_text SET col3='c' WHERE col3 = 'b' AND col5 = 1;
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;
DELETE FROM mpp21090_drop_multicol_dml_text WHERE col3='c';
SELECT * FROM mpp21090_drop_multicol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_char;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_char VALUES('x','x','a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_char ADD COLUMN col5 char DEFAULT 'x';
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_char SELECT 'z','z','b',1, 'z';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_char DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_char SELECT 'z','c',1, 'z';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_char SET col5 = '-' WHERE col2 = 'z' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_char SET col2 = '-' WHERE col2 = 'z' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_decimal;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_decimal ADD COLUMN col5 decimal DEFAULT 2.00;
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_decimal SELECT 35.00,35.00,'b',1, 35.00;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_decimal DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_decimal SELECT 35.00,'c',1, 35.00;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_decimal SET col5 = 1.00 WHERE col2 = 35.00 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_decimal SET col2 = 1.00 WHERE col2 = 35.00 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_int4;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int4 ADD COLUMN col5 int4 DEFAULT 20000000;
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int4 SELECT 35000000,35000000,'b',1, 35000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int4 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int4 SELECT 35000000,'c',1, 35000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_int4 SET col5 = 10000000 WHERE col2 = 35000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_int4 SET col2 = 10000000 WHERE col2 = 35000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_int8;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int8 VALUES(2000000000000000000,2000000000000000000,'a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int8 ADD COLUMN col5 int8 DEFAULT 2000000000000000000;
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int8 SELECT 3500000000000000000,3500000000000000000,'b',1, 3500000000000000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_int8 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_int8 SELECT 3500000000000000000,'c',1, 3500000000000000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_int8 SET col5 = 1000000000000000000 WHERE col2 = 3500000000000000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_interval;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_interval VALUES('1 hour','1 hour','a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_interval ADD COLUMN col5 interval DEFAULT '1 hour';
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_interval SELECT '14 hours','14 hours','b',1, '14 hours';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_interval DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_interval SELECT '14 hours','c',1, '14 hours';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_interval SET col5 = '12 hours' WHERE col2 = '14 hours' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_interval SET col2 = '12 hours' WHERE col2 = '14 hours' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_numeric;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_numeric SELECT 35.000000,35.000000,'b',1, 35.000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_numeric DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_numeric SELECT 35.000000,'c',1, 35.000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_numeric SET col5 = 1.000000 WHERE col2 = 35.000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addcol_addpt_dropcol_text;
CREATE TABLE mpp21090_pttab_addcol_addpt_dropcol_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0);

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_text ADD COLUMN col5 text DEFAULT 'abcdefghijklmnop';
ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_text SELECT 'xyz','xyz','b',1, 'xyz';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addcol_addpt_dropcol_text DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addcol_addpt_dropcol_text SELECT 'xyz','c',1, 'xyz';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addcol_addpt_dropcol_text SET col5 = 'qrstuvwxyz' WHERE col2 = 'xyz' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addcol_addpt_dropcol_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' and col3='c';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addcol_addpt_dropcol_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_addcol_addpt_dropcol_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_char;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_char VALUES('x','x','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_char SELECT 'z','z','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_char DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_char SELECT 'z','c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_char ADD COLUMN col5 char DEFAULT 'x';

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_char SELECT 'z','d',1,'z';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_char SET col4 = 10 WHERE col2 = 'z';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_char SET col2 = '-' WHERE col2 = 'z';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_decimal;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_decimal SELECT 35.00,35.00,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_decimal SELECT 35.00,'c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ADD COLUMN col5 decimal DEFAULT 2.00;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_decimal SELECT 35.00,'d',1,35.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal SET col4 = 10 WHERE col2 = 35.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_decimal SET col2 = 1.00 WHERE col2 = 35.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_int4;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int4 SELECT 35000000,35000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int4 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int4 SELECT 35000000,'c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ADD COLUMN col5 int4 DEFAULT 20000000;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int4 SELECT 35000000,'d',1,35000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_int4 SET col4 = 10 WHERE col2 = 35000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_int4 SET col2 = 10000000 WHERE col2 = 35000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_int8;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int8 SELECT 3500000000000000000,3500000000000000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int8 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int8 SELECT 3500000000000000000,'c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ADD COLUMN col5 int8 DEFAULT 2000000000000000000;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_int8 SELECT 3500000000000000000,'d',1,3500000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_int8 SET col4 = 10 WHERE col2 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_interval;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_interval VALUES('1 hour','1 hour','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_interval SELECT '14 hours','14 hours','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_interval DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_interval SELECT '14 hours','c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_interval ADD COLUMN col5 interval DEFAULT '1 hour';

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_interval SELECT '14 hours','d',1,'14 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_interval SET col4 = 10 WHERE col2 = '14 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_interval SET col2 = '12 hours' WHERE col2 = '14 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_numeric;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,35.000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,'c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SELECT 35.000000,'d',1,35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SET col4 = 10 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_addcol_dml_text;
CREATE TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_text SELECT 'xyz','xyz','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_text DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_text SELECT 'xyz','c',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_addcol_dml_text ADD COLUMN col5 text DEFAULT 'abcdefghijklmnop';

INSERT INTO mpp21090_pttab_addpt_dropcol_addcol_dml_text SELECT 'xyz','d',1,'xyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_text SET col4 = 10 WHERE col2 = 'xyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_addcol_dml_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_addcol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_char;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_char VALUES('x','x','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_char SELECT 'z','z','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_char DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_char SELECT 'z','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_char SET col4 = 10 WHERE col2 = 'z';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_char SET col2 = '-' WHERE col2 = 'z';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_decimal;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_decimal SELECT 35.00,35.00,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_decimal DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_decimal SELECT 35.00,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_decimal SET col4 = 10 WHERE col2 = 35.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_decimal SET col2 = 1.00 WHERE col2 = 35.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_int4;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int4 SELECT 35000000,35000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_int4 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int4 SELECT 35000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_int4 SET col4 = 10 WHERE col2 = 35000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_int4 SET col2 = 10000000 WHERE col2 = 35000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_int8;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int8 SELECT 3500000000000000000,3500000000000000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_int8 DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_int8 SELECT 3500000000000000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_int8 SET col4 = 10 WHERE col2 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_interval;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_interval VALUES('1 hour','1 hour','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_interval SELECT '14 hours','14 hours','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_interval DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_interval SELECT '14 hours','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_interval SET col4 = 10 WHERE col2 = '14 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_interval SET col2 = '12 hours' WHERE col2 = '14 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_numeric;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_numeric SELECT 35.000000,35.000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_numeric DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_numeric SELECT 35.000000,'b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_numeric SET col4 = 10 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_addpt_dropcol_dml_text;
CREATE TABLE mpp21090_pttab_addpt_dropcol_dml_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0);

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_text SELECT 'xyz','xyz','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_addpt_dropcol_dml_text DROP COLUMN col1;

INSERT INTO mpp21090_pttab_addpt_dropcol_dml_text SELECT 'xyz','b',1;
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_addpt_dropcol_dml_text SET col4 = 10 WHERE col2 = 'xyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_addpt_dropcol_dml_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_addpt_dropcol_dml_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_addpt_dropcol_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_char;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_char VALUES('x','x','a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_char DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_char VALUES('x','x','b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_char ADD COLUMN col5 char DEFAULT 'x';

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_char SELECT 'x','x','c','x';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_char SET col5 = '-' WHERE col2 = 'x' AND col1 = 'x';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char WHERE col5 = '-';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_char ADD PARTITION partfour VALUES('y','z','-');
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_char ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_char SELECT 'z','z','d','z';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_char SET col5 = '-' WHERE col2 = 'z' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_char SET col2 = '-' WHERE col2 = 'z' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char WHERE col5 = '-';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_decimal;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_decimal VALUES(2.00,2.00,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ADD COLUMN col5 decimal DEFAULT 2.00;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_decimal SELECT 2.00,2.00,'c',2.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal SET col5 = 1.00 WHERE col2 = 2.00 AND col1 = 2.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal WHERE col5 = 1.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_decimal SELECT 35.00,35.00,'d',35.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal SET col5 = 1.00 WHERE col2 = 35.00 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal WHERE col5 = 1.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_int4;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int4 VALUES(20000000,20000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ADD COLUMN col5 int4 DEFAULT 20000000;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int4 SELECT 20000000,20000000,'c',20000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 SET col5 = 10000000 WHERE col2 = 20000000 AND col1 = 20000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 WHERE col5 = 10000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ADD PARTITION partfour start(300000001) end(400000001);
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int4 SELECT 35000000,35000000,'d',35000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 SET col5 = 10000000 WHERE col2 = 35000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 WHERE col5 = 10000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_int8;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int8 VALUES(2000000000000000000,2000000000000000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ADD COLUMN col5 int8 DEFAULT 2000000000000000000;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int8 SELECT 2000000000000000000,2000000000000000000,'c',2000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 SET col5 = 1000000000000000000 WHERE col2 = 2000000000000000000 AND col1 = 2000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 WHERE col5 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_int8 SELECT 3500000000000000000,3500000000000000000,'d',3500000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 SET col5 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 WHERE col5 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_interval;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_interval VALUES('1 hour','1 hour','a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_interval DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_interval VALUES('1 hour','1 hour','b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_interval ADD COLUMN col5 interval DEFAULT '1 hour';

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_interval SELECT '1 hour','1 hour','c','1 hour';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_interval SET col5 = '12 hours' WHERE col2 = '1 hour' AND col1 = '1 hour';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval WHERE col5 = '12 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_interval ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_interval SELECT '14 hours','14 hours','d','14 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_interval SET col5 = '12 hours' WHERE col2 = '14 hours' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_interval SET col2 = '12 hours' WHERE col2 = '14 hours' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval WHERE col5 = '12 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_numeric;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_numeric VALUES(2.000000,2.000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_numeric SELECT 2.000000,2.000000,'c',2.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric SET col5 = 1.000000 WHERE col2 = 2.000000 AND col1 = 2.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric WHERE col5 = 1.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_numeric SELECT 35.000000,35.000000,'d',35.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric SET col5 = 1.000000 WHERE col2 = 35.000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric WHERE col5 = 1.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_dml_text;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_text DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_text VALUES('abcdefghijklmnop','abcdefghijklmnop','b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_text ADD COLUMN col5 text DEFAULT 'abcdefghijklmnop';

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_text SELECT 'abcdefghijklmnop','abcdefghijklmnop','c','abcdefghijklmnop';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_text SET col5 = 'qrstuvwxyz' WHERE col2 = 'abcdefghijklmnop' AND col1 = 'abcdefghijklmnop';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text WHERE col5 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_text ADD PARTITION partfour VALUES('xyz');
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_dml_text ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_dml_text SELECT 'xyz','xyz','d','xyz';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_text SET col5 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_dml_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text WHERE col5 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_dml_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char VALUES('g','g','a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char VALUES('g','g','b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ADD COLUMN col5 char DEFAULT 'g';

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_char;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_char on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char SELECT 'g','g','c','g';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char SET col5 = 'a' WHERE col2 = 'g' AND col1 = 'g';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char WHERE col5 = 'a';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ADD PARTITION partfour VALUES('y','z','-');
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char SELECT 'z','z','d','z';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char SET col5 = 'a' WHERE col2 = 'z' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char SET col2 = 'a' WHERE col2 = 'z' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char WHERE col5 = 'a';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal VALUES(2.00,2.00,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal VALUES(2.00,2.00,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ADD COLUMN col5 decimal DEFAULT 2.00;

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_decimal;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_decimal on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal SELECT 2.00,2.00,'c',2.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal SET col5 = 1.00 WHERE col2 = 2.00 AND col1 = 2.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal WHERE col5 = 1.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal SELECT 35.00,35.00,'d',35.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal SET col5 = 1.00 WHERE col2 = 35.00 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal WHERE col5 = 1.00;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 VALUES(20000000,20000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 VALUES(20000000,20000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ADD COLUMN col5 int4 DEFAULT 20000000;

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_int4;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_int4 on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 SELECT 20000000,20000000,'c',20000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 SET col5 = 10000000 WHERE col2 = 20000000 AND col1 = 20000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 WHERE col5 = 10000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ADD PARTITION partfour start(300000001) end(400000001);
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 SELECT 350000000,350000000,'d',350000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 SET col5 = 10000000 WHERE col2 = 350000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 SET col2 = 10000000 WHERE col2 = 350000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 WHERE col5 = 10000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 VALUES(200000000000000000,200000000000000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 VALUES(200000000000000000,200000000000000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ADD COLUMN col5 int8 DEFAULT 200000000000000000;

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_int8;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_int8 on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 SELECT 200000000000000000,200000000000000000,'c',200000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 SET col5 = 1000000000000000000 WHERE col2 = 200000000000000000 AND col1 = 200000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 WHERE col5 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 SELECT 3500000000000000000,3500000000000000000,'d',3500000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 SET col5 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 WHERE col5 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval VALUES('10 secs','10 secs','a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval VALUES('10 secs','10 secs','b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ADD COLUMN col5 interval DEFAULT '10 secs';

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_interval;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_interval on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval SELECT '10 secs','10 secs','c','10 secs';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval SET col5 = '11 hours' WHERE col2 = '10 secs' AND col1 = '10 secs';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval WHERE col5 = '11 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval SELECT '14 hours','14 hours','d','14 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval SET col5 = '11 hours' WHERE col2 = '14 hours' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval SET col2 = '11 hours' WHERE col2 = '14 hours' AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval WHERE col5 = '11 hours';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric;
CREATE TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric VALUES(2.000000,2.000000,'a',0);

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric DROP COLUMN col4;
INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric VALUES(2.000000,2.000000,'b');

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ADD COLUMN col5 numeric DEFAULT 2.000000;

DROP INDEX IF EXISTS mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_numeric;
CREATE INDEX mpp21090_pttab_dropcol_addcol_addpt_idx_dml_idx_numeric on mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric(col5);

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric SELECT 2.000000,2.000000,'c',2.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric SET col5 = 1.000000 WHERE col2 = 2.000000 AND col1 = 2.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric WHERE col5 = 1.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;
ALTER TABLE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ADD DEFAULT partition def;

INSERT INTO mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric SELECT 35.000000,35.000000,'d',35.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric SET col5 = 1.000000 WHERE col2 = 35.000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col3 ='d';
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric WHERE col5 = 1.000000;
SELECT * FROM mpp21090_pttab_dropcol_addcol_addpt_idx_dml_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_char;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_char VALUES('x','x','a','x',0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_char DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_char SELECT 'z','b','z', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_char SET col4 = '-' WHERE col2 = 'z' AND col4 = 'z';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_char SET col2 = '-' WHERE col2 = 'z' AND col4 = '-';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_decimal;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_decimal VALUES(2.00,2.00,'a',2.00,0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_decimal SELECT 35.00,'b',35.00, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_decimal SET col4 = 1.00 WHERE col2 = 35.00 AND col4 = 35.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col4 = 1.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_char;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_char VALUES('g','g','a','g',0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_char;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_char on mpp21090_pttab_dropfirstcol_addpt_index_char(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_char DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_char SELECT 'z','b','z', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_char ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_char SET col4 = 'a' WHERE col2 = 'z' AND col4 = 'z';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_char SET col2 = 'a' WHERE col2 = 'z' AND col4 = 'a';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_char WHERE col2 = 'a';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_decimal;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_decimal VALUES(2.00,2.00,'a',2.00,0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_decimal;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_decimal on mpp21090_pttab_dropfirstcol_addpt_index_decimal(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_decimal SELECT 35.00,'b',35.00, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_decimal ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_decimal SET col4 = 1.00 WHERE col2 = 35.00 AND col4 = 35.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col4 = 1.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_int4;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_int4 VALUES(20000000,20000000,'a',20000000,0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_int4;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_int4 on mpp21090_pttab_dropfirstcol_addpt_index_int4(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_int4 SELECT 350000000,'b',350000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_int4 SET col4 = 10000000 WHERE col2 = 350000000 AND col4 = 350000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_int4 SET col2 = 10000000 WHERE col2 = 350000000 AND col4 = 10000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_int8;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_int8 VALUES(200000000000000000,200000000000000000,'a',200000000000000000,0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_int8;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_int8 on mpp21090_pttab_dropfirstcol_addpt_index_int8(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_int8 SELECT 3500000000000000000,'b',3500000000000000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_int8 SET col4 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col4 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col4 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_interval;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_interval VALUES('10 secs','10 secs','a','10 secs',0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_interval;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_interval on mpp21090_pttab_dropfirstcol_addpt_index_interval(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_interval DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_interval SELECT '14 hours','b','14 hours', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_interval SET col4 = '11 hours' WHERE col2 = '14 hours' AND col4 = '14 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_interval SET col2 = '11 hours' WHERE col2 = '14 hours' AND col4 = '11 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_interval WHERE col2 = '11 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_numeric;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_index_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_numeric VALUES(2.000000,2.000000,'a',2.000000,0);

DROP INDEX IF EXISTS mpp21090_pttab_dropfirstcol_addpt_index_idx_numeric;
CREATE INDEX mpp21090_pttab_dropfirstcol_addpt_index_idx_numeric on mpp21090_pttab_dropfirstcol_addpt_index_numeric(col2);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_index_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_index_numeric SELECT 35.000000,'b',35.000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_index_numeric SET col4 = 1.000000 WHERE col2 = 35.000000 AND col4 = 35.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_index_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col4 = 1.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_index_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_index_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_int4;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_int4 VALUES(20000000,20000000,'a',20000000,0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_int4 SELECT 35000000,'b',35000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int4 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_int4 SET col4 = 10000000 WHERE col2 = 35000000 AND col4 = 35000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col4 = 10000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_int8;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000,0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_int8 SELECT 3500000000000000000,'b',3500000000000000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int8 ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_int8 SET col4 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col4 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col4 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_interval;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_interval VALUES('1 hour','1 hour','a','1 hour',0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_interval DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_interval SELECT '14 hours','b','14 hours', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_interval ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_interval SET col4 = '12 hours' WHERE col2 = '14 hours' AND col4 = '14 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_interval SET col2 = '12 hours' WHERE col2 = '14 hours' AND col4 = '12 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_numeric;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_numeric VALUES(2.000000,2.000000,'a',2.000000,0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_numeric SELECT 35.000000,'b',35.000000, 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_numeric ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_numeric SET col4 = 1.000000 WHERE col2 = 35.000000 AND col4 = 35.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col4 = 1.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropfirstcol_addpt_text;
CREATE TABLE mpp21090_pttab_dropfirstcol_addpt_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 text,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a','abcdefghijklmnop',0);

ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_text DROP COLUMN col1;
ALTER TABLE mpp21090_pttab_dropfirstcol_addpt_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_dropfirstcol_addpt_text SELECT 'xyz','b','xyz', 1;
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_text ORDER BY 1,2,3;

UPDATE mpp21090_pttab_dropfirstcol_addpt_text SET col4 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col4 = 'xyz';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropfirstcol_addpt_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col4 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropfirstcol_addpt_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropfirstcol_addpt_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_char;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int,
    col5 char
    
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_droplastcol_addpt_char VALUES('x','x','a',0,'x');

ALTER TABLE mpp21090_pttab_droplastcol_addpt_char DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_droplastcol_addpt_char SELECT 'z','z','b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_char SET col1 = '-' WHERE col2 = 'z' AND col1 = 'z';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_char SET col2 = '-' WHERE col2 = 'z' AND col1 = '-';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_decimal;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int,
    col5 decimal
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_droplastcol_addpt_decimal VALUES(2.00,2.00,'a',0,2.00);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_decimal DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_droplastcol_addpt_decimal SELECT 35.00,35.00,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_decimal SET col1 = 1.00 WHERE col2 = 35.00 AND col1 = 35.00;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col1 = 1.00;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_int4;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int,
    col5 int4
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_droplastcol_addpt_int4 VALUES(20000000,20000000,'a',0,20000000);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_int4 DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_droplastcol_addpt_int4 SELECT 35000000,35000000,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_int4 SET col1 = 10000000 WHERE col2 = 35000000 AND col1 = 35000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col1 = 10000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_int8;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int,
    col5 int8
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_droplastcol_addpt_int8 VALUES(2000000000000000000,2000000000000000000,'a',0,2000000000000000000);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_int8 DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_droplastcol_addpt_int8 SELECT 3500000000000000000,3500000000000000000,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_int8 SET col1 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_interval;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int,
    col5 interval
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_droplastcol_addpt_interval VALUES('1 hour','1 hour','a',0,'1 hour');

ALTER TABLE mpp21090_pttab_droplastcol_addpt_interval DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_droplastcol_addpt_interval SELECT '14 hours','14 hours','b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_interval SET col1 = '12 hours' WHERE col2 = '14 hours' AND col1 = '14 hours';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_interval SET col2 = '12 hours' WHERE col2 = '14 hours' AND col1 = '12 hours';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_numeric;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int,
    col5 numeric
    
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_droplastcol_addpt_numeric VALUES(2.000000,2.000000,'a',0,2.000000);

ALTER TABLE mpp21090_pttab_droplastcol_addpt_numeric DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_droplastcol_addpt_numeric SELECT 35.000000,35.000000,'b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_numeric SET col1 = 1.000000 WHERE col2 = 35.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_droplastcol_addpt_text;
CREATE TABLE mpp21090_pttab_droplastcol_addpt_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 int,
    col5 text
    
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_droplastcol_addpt_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a',0,'abcdefghijklmnop');

ALTER TABLE mpp21090_pttab_droplastcol_addpt_text DROP COLUMN col5;
ALTER TABLE mpp21090_pttab_droplastcol_addpt_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_droplastcol_addpt_text SELECT 'xyz','xyz','b',1;
SELECT * FROM mpp21090_pttab_droplastcol_addpt_text ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_droplastcol_addpt_text SET col1 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'xyz';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_droplastcol_addpt_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_droplastcol_addpt_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_droplastcol_addpt_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_char;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_char VALUES('x','x','a','x',0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_char DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_char ADD PARTITION partfour VALUES('y','z','-');

INSERT INTO mpp21090_pttab_dropmidcol_addpt_char SELECT 'z', 'z','b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_char ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_char SET col1 = '-' WHERE col2 = 'z' AND col1 = 'z';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_char ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_char SET col2 = '-' WHERE col2 = 'z' AND col1 = '-';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_char ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_char WHERE col2 = '-';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_char ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_decimal;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_decimal VALUES(2.00,2.00,'a',2.00,0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_decimal DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_decimal ADD PARTITION partfour start(30.00) end(40.00) inclusive;

INSERT INTO mpp21090_pttab_dropmidcol_addpt_decimal SELECT 35.00, 35.00,'b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_decimal ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_decimal SET col1 = 1.00 WHERE col2 = 35.00 AND col1 = 35.00;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_decimal ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_decimal SET col2 = 1.00 WHERE col2 = 35.00 AND col1 = 1.00;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_decimal WHERE col2 = 1.00;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_decimal ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_int4;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_int4 VALUES(20000000,20000000,'a',20000000,0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_int4 DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_int4 ADD PARTITION partfour start(300000001) end(400000001);

INSERT INTO mpp21090_pttab_dropmidcol_addpt_int4 SELECT 35000000, 35000000,'b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int4 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_int4 SET col1 = 10000000 WHERE col2 = 35000000 AND col1 = 35000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int4 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_int4 SET col2 = 10000000 WHERE col2 = 35000000 AND col1 = 10000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_int4 WHERE col2 = 10000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int4 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_int8;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_int8 VALUES(2000000000000000000,2000000000000000000,'a',2000000000000000000,0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_int8 DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_int8 ADD PARTITION partfour start(3000000000000000001) end(4000000000000000001);

INSERT INTO mpp21090_pttab_dropmidcol_addpt_int8 SELECT 3500000000000000000, 3500000000000000000,'b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int8 ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_int8 SET col1 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 3500000000000000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int8 ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_int8 SET col2 = 1000000000000000000 WHERE col2 = 3500000000000000000 AND col1 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_int8 WHERE col2 = 1000000000000000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_int8 ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_interval;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_interval VALUES('1 hour','1 hour','a','1 hour',0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_interval DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_interval ADD PARTITION partfour start('12 hours') end('1 day') inclusive;

INSERT INTO mpp21090_pttab_dropmidcol_addpt_interval SELECT '14 hours', '14 hours','b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_interval ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_interval SET col1 = '12 hours' WHERE col2 = '14 hours' AND col1 = '14 hours';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_interval ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_interval SET col2 = '12 hours' WHERE col2 = '14 hours' AND col1 = '12 hours';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_interval WHERE col2 = '12 hours';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_interval ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_numeric;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_numeric VALUES(2.000000,2.000000,'a',2.000000,0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_numeric DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_numeric ADD PARTITION partfour start(30.000000) end(40.000000) inclusive;

INSERT INTO mpp21090_pttab_dropmidcol_addpt_numeric SELECT 35.000000, 35.000000,'b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_numeric ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_numeric SET col1 = 1.000000 WHERE col2 = 35.000000 AND col1 = 35.000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_numeric ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_numeric SET col2 = 1.000000 WHERE col2 = 35.000000 AND col1 = 1.000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_numeric WHERE col2 = 1.000000;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_numeric ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_pttab_dropmidcol_addpt_text;
CREATE TABLE mpp21090_pttab_dropmidcol_addpt_text
(
    col1 text,
    col2 text,
    col3 char,
    col4 text,
    col5 int
) 
DISTRIBUTED by (col1) 
PARTITION BY LIST(col2)(partition partone VALUES('abcdefghijklmnop') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('qrstuvwxyz') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('ghi'));

INSERT INTO mpp21090_pttab_dropmidcol_addpt_text VALUES('abcdefghijklmnop','abcdefghijklmnop','a','abcdefghijklmnop',0);

ALTER TABLE mpp21090_pttab_dropmidcol_addpt_text DROP COLUMN col4;
ALTER TABLE mpp21090_pttab_dropmidcol_addpt_text ADD PARTITION partfour VALUES('xyz');

INSERT INTO mpp21090_pttab_dropmidcol_addpt_text SELECT 'xyz', 'xyz','b', 1;
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_text ORDER BY 1,2,3;

-- Update distribution key
UPDATE mpp21090_pttab_dropmidcol_addpt_text SET col1 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'xyz';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_text ORDER BY 1,2,3;

-- Update partition key
UPDATE mpp21090_pttab_dropmidcol_addpt_text SET col2 = 'qrstuvwxyz' WHERE col2 = 'xyz' AND col1 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_text ORDER BY 1,2,3;

DELETE FROM mpp21090_pttab_dropmidcol_addpt_text WHERE col2 = 'qrstuvwxyz';
SELECT * FROM mpp21090_pttab_dropmidcol_addpt_text ORDER BY 1,2,3;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_char;
CREATE TABLE mpp21090_reordered_col_dml_char
(
    col1 char DEFAULT 'a',
    col2 char,
    col3 char,
    col4 char,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_reordered_col_dml_char(col2,col1,col3,col5,col4) SELECT 'g', 'g','a', 1,'g';
INSERT INTO mpp21090_reordered_col_dml_char(col2,col3,col5,col4) SELECT 'g','b', 2, 'g'; 
SELECT * FROM mpp21090_reordered_col_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_char DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_char ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_char(col2,col3,col5,col4) SELECT 'g','c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_char ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_char SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_char ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_char WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_char ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_decimal;
CREATE TABLE mpp21090_reordered_col_dml_decimal
(
    col1 decimal DEFAULT 1.00,
    col2 decimal,
    col3 char,
    col4 decimal,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_reordered_col_dml_decimal(col2,col1,col3,col5,col4) SELECT 2.00, 2.00,'a', 1,2.00;
INSERT INTO mpp21090_reordered_col_dml_decimal(col2,col3,col5,col4) SELECT 2.00,'b', 2, 2.00; 
SELECT * FROM mpp21090_reordered_col_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_decimal DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_decimal ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_decimal(col2,col3,col5,col4) SELECT 2.00,'c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_decimal ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_decimal SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_decimal ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_decimal WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_decimal ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_int4;
CREATE TABLE mpp21090_reordered_col_dml_int4
(
    col1 int4 DEFAULT 10000000,
    col2 int4,
    col3 char,
    col4 int4,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_reordered_col_dml_int4(col2,col1,col3,col5,col4) SELECT 20000000, 20000000,'a', 1,20000000;
INSERT INTO mpp21090_reordered_col_dml_int4(col2,col3,col5,col4) SELECT 20000000,'b', 2, 20000000; 
SELECT * FROM mpp21090_reordered_col_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_int4 DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_int4 ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_int4(col2,col3,col5,col4) SELECT 20000000,'c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_int4 ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_int4 SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_int4 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_int4 WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_int4 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_int8;
CREATE TABLE mpp21090_reordered_col_dml_int8
(
    col1 int8 DEFAULT 1000000000000000000,
    col2 int8,
    col3 char,
    col4 int8,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_reordered_col_dml_int8(col2,col1,col3,col5,col4) SELECT 200000000000000000, 200000000000000000,'a', 1,200000000000000000;
INSERT INTO mpp21090_reordered_col_dml_int8(col2,col3,col5,col4) SELECT 200000000000000000,'b', 2, 200000000000000000; 
SELECT * FROM mpp21090_reordered_col_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_int8 DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_int8 ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_int8(col2,col3,col5,col4) SELECT 200000000000000000,'c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_int8 ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_int8 SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_int8 ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_int8 WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_int8 ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_interval;
CREATE TABLE mpp21090_reordered_col_dml_interval
(
    col1 interval DEFAULT '11 hours',
    col2 interval,
    col3 char,
    col4 interval,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_reordered_col_dml_interval(col2,col1,col3,col5,col4) SELECT '10 secs', '10 secs','a', 1,'10 secs';
INSERT INTO mpp21090_reordered_col_dml_interval(col2,col3,col5,col4) SELECT '10 secs','b', 2, '10 secs'; 
SELECT * FROM mpp21090_reordered_col_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_interval DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_interval ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_interval(col2,col3,col5,col4) SELECT '10 secs','c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_interval ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_interval SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_interval ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_interval WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_interval ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_reordered_col_dml_numeric;
CREATE TABLE mpp21090_reordered_col_dml_numeric
(
    col1 numeric DEFAULT 1.000000,
    col2 numeric,
    col3 char,
    col4 numeric,
    col5 int
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_reordered_col_dml_numeric(col2,col1,col3,col5,col4) SELECT 2.000000, 2.000000,'a', 1,2.000000;
INSERT INTO mpp21090_reordered_col_dml_numeric(col2,col3,col5,col4) SELECT 2.000000,'b', 2, 2.000000; 
SELECT * FROM mpp21090_reordered_col_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_reordered_col_dml_numeric DROP COLUMN col4;
ALTER TABLE mpp21090_reordered_col_dml_numeric ADD COLUMN col4 int DEFAULT 10;

INSERT INTO mpp21090_reordered_col_dml_numeric(col2,col3,col5,col4) SELECT 2.000000,'c', 2, 10; 
SELECT * FROM mpp21090_reordered_col_dml_numeric ORDER BY 1,2,3,4;

UPDATE mpp21090_reordered_col_dml_numeric SET col4 = 20;
SELECT * FROM mpp21090_reordered_col_dml_numeric ORDER BY 1,2,3,4;

DELETE FROM mpp21090_reordered_col_dml_numeric WHERE col4=20;
SELECT * FROM mpp21090_reordered_col_dml_numeric ORDER BY 1,2,3,4;


-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_char;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int,
    col5 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_char VALUES('g','g','a',0, 'g');
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char ADD COLUMN col1 char DEFAULT 'g';

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_char including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate VALUES('g','z',1,'g','g');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char EXCHANGE PARTITION FOR('d') WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_char SELECT  'a','b', 1, 'a', 'a';
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_char;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_char SET col5 = 'z' WHERE col2 = 'a' AND col5 = 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_char SET col2 ='g' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate SELECT 'a','b', 1, 'a', 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate SET col2='g' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_char_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_decimal;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int,
    col5 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_decimal VALUES(2.00,2.00,'a',0, 2.00);
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ADD COLUMN col1 decimal DEFAULT 2.00;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_decimal including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate VALUES(2.00,'z',1,2.00,2.00);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal EXCHANGE PARTITION FOR(5.00) WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_decimal SELECT  1.00,'b', 1, 1.00, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal SET col5 = 35.00 WHERE col2 = 1.00 AND col5 = 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal SET col2 =2.00 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate SELECT 1.00,'b', 1, 1.00, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate SET col2=2.00 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_decimal_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_int4;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int,
    col5 int4
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int4 VALUES(20000000,20000000,'a',0, 20000000);
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_int4;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4 DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ADD COLUMN col1 int4 DEFAULT 20000000;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_int4 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate VALUES(20000000,'z',1,20000000,20000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4 EXCHANGE PARTITION FOR(50000000) WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int4 SELECT  10000000,'b', 1, 10000000, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int4 SET col5 = 350000000 WHERE col2 = 10000000 AND col5 = 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int4 SET col2 =20000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate SELECT 10000000,'b', 1, 10000000, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate SET col2=20000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int4_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_int8;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int,
    col5 int8
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int8 VALUES(200000000000000000,200000000000000000,'a',0, 200000000000000000);
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_int8;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8 DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ADD COLUMN col1 int8 DEFAULT 200000000000000000;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_int8 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate VALUES(200000000000000000,'z',1,200000000000000000,200000000000000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8 EXCHANGE PARTITION FOR(500000000000000000) WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int8 SELECT  100000000000000000,'b', 1, 100000000000000000, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int8 SET col5 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col5 = 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int8 SET col2 =200000000000000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate SELECT 100000000000000000,'b', 1, 100000000000000000, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate SET col2=200000000000000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_int8_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_interval;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int,
    col5 interval
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_interval VALUES('10 secs','10 secs','a',0, '10 secs');
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_interval;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval ADD COLUMN col1 interval DEFAULT '10 secs';

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_interval including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate VALUES('10 secs','z',1,'10 secs','10 secs');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval EXCHANGE PARTITION FOR('30 secs') WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_interval SELECT  '1 sec','b', 1, '1 sec', '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_interval SET col5 = '14 hours' WHERE col2 = '1 sec' AND col5 = '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_interval SET col2 ='10 secs' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate SELECT '1 sec','b', 1, '1 sec', '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate SET col2='10 secs' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_interval_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_numeric;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int,
    col5 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_numeric VALUES(2.000000,2.000000,'a',0, 2.000000);
ANALYZE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric DROP COLUMN col1;
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ADD COLUMN col1 numeric DEFAULT 2.000000;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate( like mpp21090_xchange_pttab_dropcol_addcol_dml_numeric including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate VALUES(2.000000,'z',1,2.000000,2.000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric EXCHANGE PARTITION FOR(5.000000) WITH TABLE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_numeric SELECT  1.000000,'b', 1, 1.000000, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric SET col5 = 35.000000 WHERE col2 = 1.000000 AND col5 = 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric SET col2 =2.000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate SELECT 1.000000,'b', 1, 1.000000, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate SET col2=2.000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_addcol_dml_numeric_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_char;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int,
    col5 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_char VALUES('g','g','a',0, 'g');
ANALYZE mpp21090_xchange_pttab_dropcol_dml_char;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_char DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_char_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_char_candidate( like mpp21090_xchange_pttab_dropcol_dml_char including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_char_candidate VALUES('g','z',1,'g');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_char EXCHANGE PARTITION FOR('d') WITH TABLE mpp21090_xchange_pttab_dropcol_dml_char_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_char SELECT  'a','b', 1, 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_char SET col5 = 'z' WHERE col2 = 'a' AND col5 = 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_char SET col2 ='g' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_char WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_char_candidate SELECT 'a','b', 1, 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_char_candidate SET col2='g' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_char_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_char_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_decimal;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int,
    col5 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_decimal VALUES(2.00,2.00,'a',0, 2.00);
ANALYZE mpp21090_xchange_pttab_dropcol_dml_decimal;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_decimal DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_decimal_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_decimal_candidate( like mpp21090_xchange_pttab_dropcol_dml_decimal including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_decimal_candidate VALUES(2.00,'z',1,2.00);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_decimal EXCHANGE PARTITION FOR(5.00) WITH TABLE mpp21090_xchange_pttab_dropcol_dml_decimal_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_decimal SELECT  1.00,'b', 1, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_decimal SET col5 = 35.00 WHERE col2 = 1.00 AND col5 = 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_decimal SET col2 =2.00 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_decimal_candidate SELECT 1.00,'b', 1, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_decimal_candidate SET col2=2.00 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_decimal_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_decimal_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_int4;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int,
    col5 int4
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int4 VALUES(20000000,20000000,'a',0, 20000000);
ANALYZE mpp21090_xchange_pttab_dropcol_dml_int4;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_int4 DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_int4_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_int4_candidate( like mpp21090_xchange_pttab_dropcol_dml_int4 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int4_candidate VALUES(20000000,'z',1,20000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_int4 EXCHANGE PARTITION FOR(50000000) WITH TABLE mpp21090_xchange_pttab_dropcol_dml_int4_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int4 SELECT  10000000,'b', 1, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int4 SET col5 = 350000000 WHERE col2 = 10000000 AND col5 = 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int4 SET col2 =20000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int4_candidate SELECT 10000000,'b', 1, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int4_candidate SET col2=20000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_int4_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int4_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_int8;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int,
    col5 int8
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int8 VALUES(200000000000000000,200000000000000000,'a',0, 200000000000000000);
ANALYZE mpp21090_xchange_pttab_dropcol_dml_int8;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_int8 DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_int8_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_int8_candidate( like mpp21090_xchange_pttab_dropcol_dml_int8 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int8_candidate VALUES(200000000000000000,'z',1,200000000000000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_int8 EXCHANGE PARTITION FOR(500000000000000000) WITH TABLE mpp21090_xchange_pttab_dropcol_dml_int8_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int8 SELECT  100000000000000000,'b', 1, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int8 SET col5 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col5 = 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int8 SET col2 =200000000000000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_int8_candidate SELECT 100000000000000000,'b', 1, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_int8_candidate SET col2=200000000000000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_int8_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_int8_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_interval;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int,
    col5 interval
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_interval VALUES('10 secs','10 secs','a',0, '10 secs');
ANALYZE mpp21090_xchange_pttab_dropcol_dml_interval;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_interval DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_interval_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_interval_candidate( like mpp21090_xchange_pttab_dropcol_dml_interval including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_interval_candidate VALUES('10 secs','z',1,'10 secs');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_interval EXCHANGE PARTITION FOR('30 secs') WITH TABLE mpp21090_xchange_pttab_dropcol_dml_interval_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_interval SELECT  '1 sec','b', 1, '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_interval SET col5 = '14 hours' WHERE col2 = '1 sec' AND col5 = '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_interval SET col2 ='10 secs' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_interval_candidate SELECT '1 sec','b', 1, '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_interval_candidate SET col2='10 secs' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_interval_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_interval_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_numeric;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int,
    col5 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_xchange_pttab_dropcol_dml_numeric VALUES(2.000000,2.000000,'a',0, 2.000000);
ANALYZE mpp21090_xchange_pttab_dropcol_dml_numeric;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3,4;

ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_numeric DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_dml_numeric_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_dml_numeric_candidate( like mpp21090_xchange_pttab_dropcol_dml_numeric including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_numeric_candidate VALUES(2.000000,'z',1,2.000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_dml_numeric EXCHANGE PARTITION FOR(5.000000) WITH TABLE mpp21090_xchange_pttab_dropcol_dml_numeric_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_numeric SELECT  1.000000,'b', 1, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_numeric SET col5 = 35.000000 WHERE col2 = 1.000000 AND col5 = 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_numeric SET col2 =2.000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_dml_numeric_candidate SELECT 1.000000,'b', 1, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_dml_numeric_candidate SET col2=2.000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_dml_numeric_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_dml_numeric_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_char;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_char
(
    col1 char,
    col2 char,
    col3 char,
    col4 int,
    col5 char
) 
DISTRIBUTED by (col1)
PARTITION BY LIST(col2)(partition partone VALUES('a','b','c','d','e','f','g','h') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo VALUES('i','j','k','l','m','n','o','p') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree VALUES('q','r','s','t','u','v','w','x'));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_char VALUES('g','g','a',0, 'g');
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_char;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_char;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_char on mpp21090_xchange_pttab_dropcol_idx_dml_char(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_char DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_char including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate VALUES('g','z',1,'g');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_char EXCHANGE PARTITION FOR('d') WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_char SELECT  'a','b', 1, 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_char SET col5 = 'z' WHERE col2 = 'a' AND col5 = 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_char SET col2 ='g' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_char WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate SELECT 'a','b', 1, 'a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate SET col2='g' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_char_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_decimal;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_decimal
(
    col1 decimal,
    col2 decimal,
    col3 char,
    col4 int,
    col5 decimal
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.00) end(10.00)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.00) end(20.00) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.00) end(30.00));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_decimal VALUES(2.00,2.00,'a',0, 2.00);
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_decimal;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_decimal;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_decimal on mpp21090_xchange_pttab_dropcol_idx_dml_decimal(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_decimal DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_decimal including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate VALUES(2.00,'z',1,2.00);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_decimal EXCHANGE PARTITION FOR(5.00) WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_decimal SELECT  1.00,'b', 1, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_decimal SET col5 = 35.00 WHERE col2 = 1.00 AND col5 = 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_decimal SET col2 =2.00 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate SELECT 1.00,'b', 1, 1.00;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate SET col2=2.00 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_decimal_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_int4;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int4
(
    col1 int4,
    col2 int4,
    col3 char,
    col4 int,
    col5 int4
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(100000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(100000001) end(200000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(200000001) end(300000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int4 VALUES(20000000,20000000,'a',0, 20000000);
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_int4;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_int4;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_int4 on mpp21090_xchange_pttab_dropcol_idx_dml_int4(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int4 DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_int4 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate VALUES(20000000,'z',1,20000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int4 EXCHANGE PARTITION FOR(50000000) WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int4 SELECT  10000000,'b', 1, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int4 SET col5 = 350000000 WHERE col2 = 10000000 AND col5 = 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int4 SET col2 =20000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate SELECT 10000000,'b', 1, 10000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate SET col2=20000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int4_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_int8;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int8
(
    col1 int8,
    col2 int8,
    col3 char,
    col4 int,
    col5 int8
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1) end(1000000000000000001)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(1000000000000000001) end(2000000000000000001) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(2000000000000000001) end(3000000000000000001));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int8 VALUES(200000000000000000,200000000000000000,'a',0, 200000000000000000);
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_int8;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_int8;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_int8 on mpp21090_xchange_pttab_dropcol_idx_dml_int8(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int8 DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_int8 including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate VALUES(200000000000000000,'z',1,200000000000000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int8 EXCHANGE PARTITION FOR(500000000000000000) WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int8 SELECT  100000000000000000,'b', 1, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int8 SET col5 = 3500000000000000000 WHERE col2 = 100000000000000000 AND col5 = 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int8 SET col2 =200000000000000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8 ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate SELECT 100000000000000000,'b', 1, 100000000000000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate SET col2=200000000000000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_int8_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_interval;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_interval
(
    col1 interval,
    col2 interval,
    col3 char,
    col4 int,
    col5 interval
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start('1 sec') end('1 min')  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start('1 min') end('1 hour') WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start('1 hour') end('12 hours'));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_interval VALUES('10 secs','10 secs','a',0, '10 secs');
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_interval;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_interval;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_interval on mpp21090_xchange_pttab_dropcol_idx_dml_interval(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_interval DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_interval including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate VALUES('10 secs','z',1,'10 secs');

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_interval EXCHANGE PARTITION FOR('30 secs') WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_interval SELECT  '1 sec','b', 1, '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_interval SET col5 = '14 hours' WHERE col2 = '1 sec' AND col5 = '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_interval SET col2 ='10 secs' WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate SELECT '1 sec','b', 1, '1 sec';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate SET col2='10 secs' WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_interval_candidate ORDER BY 1,2,3;

-- TEST
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_numeric;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_numeric
(
    col1 numeric,
    col2 numeric,
    col3 char,
    col4 int,
    col5 numeric
) 
DISTRIBUTED by (col1)
PARTITION BY RANGE(col2)(partition partone start(1.000000) end(10.000000)  WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=column),partition parttwo start(10.000000) end(20.000000) WITH (APPENDONLY=true, COMPRESSLEVEL=5, ORIENTATION=row),partition partthree start(20.000000) end(30.000000));

INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_numeric VALUES(2.000000,2.000000,'a',0, 2.000000);
ANALYZE mpp21090_xchange_pttab_dropcol_idx_dml_numeric;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3,4;

DROP INDEX IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_idx_numeric;
CREATE INDEX mpp21090_xchange_pttab_dropcol_idx_dml_idx_numeric on mpp21090_xchange_pttab_dropcol_idx_dml_numeric(col2);

ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_numeric DROP COLUMN col1;

-- Create Candidate table for Exchange
DROP TABLE IF EXISTS mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate;
CREATE TABLE mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate( like mpp21090_xchange_pttab_dropcol_idx_dml_numeric including indexes) distributed randomly;
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate VALUES(2.000000,'z',1,2.000000);

-- Exchange 
ALTER TABLE mpp21090_xchange_pttab_dropcol_idx_dml_numeric EXCHANGE PARTITION FOR(5.000000) WITH TABLE mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate;

SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate ORDER BY 1,2,3;

-- DML on partition table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_numeric SELECT  1.000000,'b', 1, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_numeric SET col5 = 35.000000 WHERE col2 = 1.000000 AND col5 = 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_numeric SET col2 =2.000000 WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric WHERE col3='b';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric ORDER BY 1,2,3;

-- DML on candidate table
INSERT INTO mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate SELECT 1.000000,'b', 1, 1.000000;
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate ORDER BY 1,2,3;

UPDATE mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate SET col2=2.000000 WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate ORDER BY 1,2,3;

DELETE FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate WHERE col3='a';
SELECT * FROM mpp21090_xchange_pttab_dropcol_idx_dml_numeric_candidate ORDER BY 1,2,3;

-- Test exchange partition contains dropped columns
DROP TABLE IF EXISTS table_with_leaf_partition_containing_dropped_column;
DROP TABLE IF EXISTS leaf_table_with_leaf_partition_containing_dropped_column;
CREATE TABLE table_with_leaf_partition_containing_dropped_column(a int, b date, z int)
DISTRIBUTED BY (a) PARTITION BY RANGE(b)
(
    START ('2021-04-11'::date) END ('2021-04-12'::date) WITH (tablename='prttab_leaf_containing_dropped_col_part1'),
    START ('2021-04-12'::date) END ('2021-04-13'::date) WITH (tablename='prttab_leaf_containing_dropped_col_part2')
);
-- Drop a column defined on leaf partition
CREATE TABLE leaf_table_with_leaf_partition_containing_dropped_column(a int, b date, z1 int, z int);
ALTER TABLE leaf_table_with_leaf_partition_containing_dropped_column DROP COLUMN z1;
ALTER TABLE table_with_leaf_partition_containing_dropped_column ALTER PARTITION FOR ('2021-04-11'::date) EXCHANGE PARTITION FOR ('2021-04-11'::date) WITH TABLE leaf_table_with_leaf_partition_containing_dropped_column;
CREATE INDEX table_with_leaf_partition_containing_dropped_column_index ON table_with_leaf_partition_containing_dropped_column(a, b);

EXPLAIN SELECT * FROM table_with_leaf_partition_containing_dropped_column WHERE a>42 and z<42;
SELECT * FROM table_with_leaf_partition_containing_dropped_column WHERE a>42 and z<42;
EXPLAIN SELECT * FROM prttab_leaf_containing_dropped_col_part1 WHERE a>42 and z<42;
SELECT * FROM prttab_leaf_containing_dropped_col_part1 WHERE a>42 and z<42;
EXPLAIN SELECT * FROM prttab_leaf_containing_dropped_col_part2 WHERE a>42 and z<42;
SELECT * FROM prttab_leaf_containing_dropped_col_part2 WHERE a>42 and z<42;

-- Test exchange partition contains dropped columns between index columns
DROP TABLE IF EXISTS table_with_leaf_containing_dropped_column_between_index_columns;
DROP TABLE IF EXISTS leaf_containing_dropped_column_between_index_columns;
CREATE TABLE table_with_leaf_containing_dropped_column_between_index_columns(a int, b date, z int)
DISTRIBUTED BY (a) PARTITION BY RANGE(b)
(
    START ('2021-04-11'::date) END ('2021-04-12'::date) WITH (tablename='leaf_containing_dropped_col_index_part1'),
    START ('2021-04-12'::date) END ('2021-04-13'::date) WITH (tablename='leaf_containing_dropped_col_index_part2')
);
-- Drop a column defined ahead of the index column
CREATE TABLE leaf_containing_dropped_column_between_index_columns(a int, d1  int, b date, z1 int, z int);
ALTER TABLE leaf_containing_dropped_column_between_index_columns DROP COLUMN z1;
ALTER TABLE leaf_containing_dropped_column_between_index_columns DROP COLUMN d1;

ALTER TABLE table_with_leaf_containing_dropped_column_between_index_columns EXCHANGE PARTITION FOR ('2021-04-11'::date) WITH TABLE leaf_containing_dropped_column_between_index_columns;
CREATE INDEX table_with_leaf_partition_dropped_col_between_index_cols_index ON table_with_leaf_containing_dropped_column_between_index_columns(a, b);

EXPLAIN SELECT * FROM table_with_leaf_containing_dropped_column_between_index_columns WHERE a>42 and z<42;
SELECT * FROM table_with_leaf_containing_dropped_column_between_index_columns WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_containing_dropped_col_index_part1 WHERE a>42 and z<42;
SELECT * FROM leaf_containing_dropped_col_index_part1 WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_containing_dropped_col_index_part2 WHERE a>42 and z<42;
SELECT * FROM leaf_containing_dropped_col_index_part2 WHERE a>42 and z<42;

-- Test exchange partition where root contains dropped columns and no dropped columns on the partition
DROP TABLE IF EXISTS table_with_root_containing_dropped_columns;
DROP TABLE IF EXISTS leaf_containing_no_dropped_columns;
CREATE TABLE table_with_root_containing_dropped_columns(a int, d1  int, b date, z1 int, z int)
DISTRIBUTED BY (a) PARTITION BY RANGE(b)
(
    START ('2021-04-11'::date) END ('2021-04-12'::date) WITH (tablename='leaf_with_root_containing_dropped_columns_part1'),
    START ('2021-04-12'::date) END ('2021-04-13'::date) WITH (tablename='leaf_with_root_containing_dropped_columns_part2')
);
-- Drop a column defined ahead of the index column
CREATE TABLE leaf_containing_no_dropped_columns(a int,  b date, z int);
ALTER TABLE table_with_root_containing_dropped_columns DROP COLUMN z1;
ALTER TABLE table_with_root_containing_dropped_columns DROP COLUMN d1;

ALTER TABLE table_with_root_containing_dropped_columns EXCHANGE PARTITION FOR ('2021-04-11'::date) WITH TABLE leaf_containing_no_dropped_columns;
CREATE INDEX table_with_root_containing_dropped_columns_index ON table_with_root_containing_dropped_columns(a, b);

EXPLAIN SELECT * FROM table_with_root_containing_dropped_columns WHERE a>42 and z<42;
SELECT * FROM table_with_root_containing_dropped_columns WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_with_root_containing_dropped_columns_part1 WHERE a>42 and z<42;
SELECT * FROM leaf_with_root_containing_dropped_columns_part1 WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_with_root_containing_dropped_columns_part2 WHERE a>42 and z<42;
SELECT * FROM leaf_with_root_containing_dropped_columns_part2 WHERE a>42 and z<42;

-- Test exchange partition where root and the exchanged partition have dropped columns at different locations
DROP TABLE IF EXISTS table_with_both_containing_dropped_column;
DROP TABLE IF EXISTS leaf_containing_dropped_columns_between_index_columns;
CREATE TABLE table_with_both_containing_dropped_column(d1 int, a int, b date, z int)
DISTRIBUTED BY (a) PARTITION BY RANGE(b)
(
    START ('2021-04-11'::date) END ('2021-04-12'::date) WITH (tablename='leaf_with_dropped_cols_index_part1'),
    START ('2021-04-12'::date) END ('2021-04-13'::date) WITH (tablename='leaf_with_dropped_cols_index_part2')
);
-- Drop columns from root as well as leaf at different locations
CREATE TABLE leaf_containing_dropped_columns_between_index_columns(a int, d1  int, z1 int, b date, z int);
ALTER TABLE table_with_both_containing_dropped_column DROP COLUMN d1;
ALTER TABLE leaf_containing_dropped_columns_between_index_columns DROP COLUMN z1;
ALTER TABLE leaf_containing_dropped_columns_between_index_columns DROP COLUMN d1;

ALTER TABLE table_with_both_containing_dropped_column EXCHANGE PARTITION FOR ('2021-04-11'::date) WITH TABLE leaf_containing_dropped_columns_between_index_columns;
CREATE INDEX table_with_both_containing_dropped_column_index ON table_with_both_containing_dropped_column(a, b);

EXPLAIN SELECT * FROM table_with_both_containing_dropped_column WHERE a>42 and z<42;
SELECT * FROM table_with_both_containing_dropped_column WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_with_dropped_cols_index_part1 WHERE a>42 and z<42;
SELECT * FROM leaf_with_dropped_cols_index_part1 WHERE a>42 and z<42;
EXPLAIN SELECT * FROM leaf_with_dropped_cols_index_part2 WHERE a>42 and z<42;
SELECT * FROM leaf_with_dropped_cols_index_part2 WHERE a>42 and z<42;

-- multi-level-partition with dropped root cols and exchanged partition
drop table if exists multi_dropped_cols_root;
CREATE TABLE multi_dropped_cols_root (trans_id int, to_be_dropped1 int, date date, amount 
decimal(9,2), to_be_dropped2 int, region text) 
DISTRIBUTED BY (trans_id)
PARTITION BY RANGE (date)
SUBPARTITION BY LIST (region)
SUBPARTITION TEMPLATE
( SUBPARTITION usa VALUES ('usa'), 
  SUBPARTITION asia VALUES ('asia'))
  (START (date '2011-01-01') INCLUSIVE
   END (date '2011-04-01') EXCLUSIVE
   EVERY (INTERVAL '3 month'));

alter table multi_dropped_cols_root drop column to_be_dropped1;
alter table multi_dropped_cols_root drop column to_be_dropped2;

drop table if exists multi_dropped_cols_root_exchange_part;
create table multi_dropped_cols_root_exchange_part (trans_id int, date date, amount 
decimal(9,2), region text);

ALTER TABLE multi_dropped_cols_root 
ALTER PARTITION FOR (RANK(1))
EXCHANGE PARTITION FOR ('usa') WITH TABLE multi_dropped_cols_root_exchange_part ;

create index idx_sales_date on multi_dropped_cols_root(date);

explain select * from multi_dropped_cols_root where date = '2011-01-01' and region = 'usa';
select * from multi_dropped_cols_root where date = '2011-01-01' and region = 'usa';

-- multi-level-partition with dropped leaf cols and exchanged partition
CREATE TABLE multi_dropped_cols_leaf (trans_id int, date date, amount 
decimal(9,2), region text) 
DISTRIBUTED BY (trans_id)
PARTITION BY RANGE (date)
SUBPARTITION BY LIST (region)
SUBPARTITION TEMPLATE
( SUBPARTITION usa VALUES ('usa'), 
  SUBPARTITION asia VALUES ('asia'))
  (START (date '2011-01-01') INCLUSIVE
   END (date '2011-04-01') EXCLUSIVE
   EVERY (INTERVAL '3 month'));

drop table if exists multi_dropped_cols_leaf_exchange_part;
create table multi_dropped_cols_leaf_exchange_part (trans_id int, to_be_dropped1, date date, amount 
decimal(9,2), to_be_dropped2, region text);
alter table multi_dropped_cols_leaf_exchange_part drop column to_be_dropped1;
alter table multi_dropped_cols_leaf_exchange_part drop column to_be_dropped2;


ALTER TABLE multi_dropped_cols_leaf 
ALTER PARTITION FOR (RANK(1))
EXCHANGE PARTITION FOR ('usa') WITH TABLE sales_exchange_part ;

create index idx_multi_dropped_cols_leaf_date on multi_dropped_cols_leaf(date);

explain select * from multi_dropped_cols_leaf where date = '2011-01-01' and region = 'usa';
select * from multi_dropped_cols_leaf where date = '2011-01-01' and region = 'usa';

-- multi-level-partition with btree index with mid level not having dropped column for added partition
CREATE TABLE multi_part_mid_btree (trans_id int, to_be_dropped1 int, date date, amount 
decimal(9,2), to_be_dropped2 int, region text) 
DISTRIBUTED BY (trans_id)
PARTITION BY RANGE (date)
SUBPARTITION BY LIST (region)
SUBPARTITION TEMPLATE
( SUBPARTITION usa VALUES ('usa'), 
  SUBPARTITION asia VALUES ('asia'))
  (START (date '2011-01-01') INCLUSIVE
   END (date '2011-04-01') EXCLUSIVE
   EVERY (INTERVAL '3 month'));

alter table multi_part_mid_btree drop column to_be_dropped1;
alter table multi_part_mid_btree drop column to_be_dropped2;

-- Create the exchange candidate without dropped columns
drop table if exists multi_part_mid_btree_exchange_part;
create table multi_part_mid_btree_exchange_part (trans_id int, date date, amount 
decimal(9,2), region text);

-- Exchange
ALTER TABLE multi_part_mid_btree 
ALTER PARTITION FOR (RANK(1))
EXCHANGE PARTITION FOR ('usa') WITH TABLE multi_part_mid_btree_exchange_part ;

ALTER TABLE multi_part_mid_btree ADD PARTITION 
            START (date '2017-02-01') INCLUSIVE 
            END (date '2017-03-01') EXCLUSIVE;

create index idx_multi_part_mid_btree on multi_part_mid_btree(date);

-- Since we have arbitrarily named partitions here, we can't match the plan
-- output for planner. It should still generate a dynamic bitmap scan for Orca.
-- start_ignore
explain select * from multi_part_mid_btree where date = '2017-02-05' and region = 'usa';
-- end_ignore
select * from multi_part_mid_btree where date = '2017-02-05' and region = 'usa';

-- multi-level-partition with bitmap index with mid level not having dropped column for added partition
CREATE TABLE multi_part_mid_bitmap (trans_id int, to_be_dropped1 int, date date, amount 
decimal(9,2), to_be_dropped2 int, region text) 
DISTRIBUTED BY (trans_id)
PARTITION BY RANGE (date)
SUBPARTITION BY LIST (region)
SUBPARTITION TEMPLATE
( SUBPARTITION usa VALUES ('usa'), 
  SUBPARTITION asia VALUES ('asia'))
  (START (date '2011-01-01') INCLUSIVE
   END (date '2011-04-01') EXCLUSIVE
   EVERY (INTERVAL '3 month'));

alter table multi_part_mid_bitmap drop column to_be_dropped1;
alter table multi_part_mid_bitmap drop column to_be_dropped2;

drop table if exists multi_part_mid_bitmap_exchange_part;
create table multi_part_mid_bitmap_exchange_part (trans_id int, date date, amount 
decimal(9,2), region text);

ALTER TABLE multi_part_mid_bitmap 
ALTER PARTITION FOR (RANK(1))
EXCHANGE PARTITION FOR ('usa') WITH TABLE multi_part_mid_bitmap_exchange_part ;

ALTER TABLE multi_part_mid_bitmap ADD PARTITION 
            START (date '2017-02-01') INCLUSIVE 
            END (date '2017-03-01') EXCLUSIVE;

create index idx_multi_part_mid_bitmap on multi_part_mid_bitmap using bitmap(date);

-- Since we have arbitrarily named partitions here, we can't match the plan
-- output for planner. It should still generate a dynamic bitmap scan for Orca.
-- start_ignore
explain select * from multi_part_mid_bitmap where date = '2017-02-05' and region = 'usa';
-- end_ignore
select * from multi_part_mid_bitmap where date = '2017-02-05' and region = 'usa';

-- Exchange partitions with dropped columns and check subplan with attribute remapping into dynamicSeqscan
-- start_ignore
DROP TABLE if exists ds_main;
DROP TABLE if exists ds_part1;
DROP TABLE if exists non_part1;
DROP TABLE if exists non_part2;
-- end_ignore

CREATE TABLE ds_main ( a INT, b INT, c INT) PARTITION BY RANGE(c)( START(1) END (10) EVERY (2), DEFAULT PARTITION deflt);
CREATE TABLE ds_part1 (a int, a1 int, b int, c int);
CREATE TABLE non_part1 (c INT);
CREATE TABLE non_part2 (e INT, f INT);

SET optimizer_enforce_subplans TO ON;

-- drop columns to get attribute remapping
ALTER TABLE ds_part1 drop column a1;
ALTER TABLE ds_main exchange partition for (1) with table ds_part1;

INSERT INTO non_part1 SELECT i FROM generate_series(1, 1)i;
INSERT INTO non_part2 SELECT i, i + 1 FROM generate_series(1, 10)i;
INSERT INTO ds_main SELECT i, i + 1, i + 2 FROM generate_series (1, 1000)i;

analyze ds_main;
analyze non_part1;
analyze non_part2;

EXPLAIN (costs off) SELECT * FROM ds_main, non_part2 WHERE ds_main.c = non_part2.e AND a IN ( SELECT a FROM non_part1) order by a;
SELECT * FROM ds_main, non_part2 WHERE ds_main.c = non_part2.e AND a IN ( SELECT a FROM non_part1) order by a;

-- Test for dropping distribution column via DROP TYPE..CASCADE
-- ensure the distribution policy for the table is updated
-- and the DML queries on the table work as expected for both
-- partitioned and non-partitioned tables
CREATE DOMAIN int_new AS int;
CREATE TABLE dist_key_dropped (a int_new, b int) DISTRIBUTED BY(a);
CREATE TABLE dist_key_dropped_pt (a int_new, b int) DISTRIBUTED BY(a)
PARTITION BY RANGE(b)
  (PARTITION p1 START(0) END(5),
   PARTITION p2 START(6) END(10));
INSERT INTO dist_key_dropped VALUES(1, 1);
INSERT INTO dist_key_dropped VALUES(2, 2);
INSERT INTO dist_key_dropped_pt VALUES(1, 1);
INSERT INTO dist_key_dropped_pt VALUES(2, 6);
DROP TYPE int_new CASCADE;
\d dist_key_dropped
\d dist_key_dropped_pt
\d dist_key_dropped_pt_1_prt_p1
\d dist_key_dropped_pt_1_prt_p2
INSERT INTO dist_key_dropped VALUES(10);
INSERT INTO dist_key_dropped_pt VALUES(7);
UPDATE dist_key_dropped SET b=11 where b=1;
UPDATE dist_key_dropped_pt SET b=2 where b=1;
SELECT * FROM dist_key_dropped;
SELECT * FROM dist_key_dropped_pt;
DELETE FROM dist_key_dropped WHERE b=2;
DELETE FROM dist_key_dropped_pt WHERE b=6;

-- As of this writing, pg_dump creates an invalid dump for some of the tables
-- here. See https://github.com/GreengageDB/greengage/issues/3598. So we must drop
-- the tables, or the pg_upgrade test fails.
set client_min_messages='warning';
drop schema qp_dropped_cols cascade;

-- Test modifying DML on leaf partition when parent has dropped columns and
-- the partition has not. Ensure that DML commands pass without execution
-- errors and produce valid results.
RESET search_path;
-- start_ignore
DROP TABLE IF EXISTS t_part_dropped;
-- end_ignore
CREATE TABLE t_part_dropped (c1 int, c2 int, c3 int, c4 int) DISTRIBUTED BY (c1)
PARTITION BY LIST (c3) (PARTITION p0 VALUES (0));

ALTER TABLE t_part_dropped DROP c2;
ALTER TABLE t_part_dropped ADD PARTITION p2 VALUES (2);

-- Partition selection should go smoothly when inserting into leaf
-- partition with different attribute structure.
EXPLAIN (COSTS OFF, VERBOSE) INSERT INTO t_part_dropped VALUES (1, 2, 4);
INSERT INTO t_part_dropped VALUES (1, 2, 4);

EXPLAIN (COSTS OFF, VERBOSE) INSERT INTO t_part_dropped_1_prt_p2 VALUES (1, 2, 4);
INSERT INTO t_part_dropped_1_prt_p2 VALUES (1, 2, 4);

INSERT INTO t_part_dropped_1_prt_p2 VALUES (1, 2, 0);

-- Ensure that split update on leaf and root partitions does not
-- throw partition selection error in both planners.
EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part_dropped_1_prt_p2 SET c1 = 2;
UPDATE t_part_dropped_1_prt_p2 SET c1 = 2;

EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part_dropped SET c1 = 3;
UPDATE t_part_dropped SET c1 = 3;

-- Ensure that split update on leaf partition does not throw constraint error
-- (executor does not choose the wrong partition at insert stage of update).
INSERT INTO t_part_dropped VALUES (1, 2, 0);
UPDATE t_part_dropped_1_prt_p2 SET c1 = 2 WHERE c4 = 0;

SELECT count(*) FROM t_part_dropped_1_prt_p2;

-- Split update on root relation should choose the correct partition
-- at insert (executor doesn't put the tuple to wrong partition for legacy
-- planner case).
EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part_dropped SET c1 = 3 WHERE c4 = 0;
UPDATE t_part_dropped SET c1 = 3 WHERE c4 = 0;

SELECT count(*) FROM t_part_dropped_1_prt_p2;
SELECT * FROM t_part_dropped_1_prt_p0;

-- For ORCA the partition selection error should not occur.
EXPLAIN (COSTS OFF, VERBOSE) DELETE FROM t_part_dropped_1_prt_p2;
DELETE FROM t_part_dropped_1_prt_p2;

DROP TABLE t_part_dropped;

-- Test modifying DML on leaf partition after it was exchanged with a relation,
-- that contained dropped columns. Ensure that DML commands pass without
-- execution errors and produce valid results.
-- start_ignore
DROP TABLE IF EXISTS t_part;
DROP TABLE IF EXISTS t_new_part;
-- end_ignore
CREATE TABLE t_part (c1 int, c2 int, c3 int, c4 int) DISTRIBUTED BY (c1)
PARTITION BY LIST (c3) (PARTITION p0 VALUES (0));

ALTER TABLE t_part ADD PARTITION p2 VALUES (2);
CREATE TABLE t_new_part (c1 int, c11 int, c2 int, c3 int, c4 int);
ALTER TABLE t_new_part DROP c11;
ALTER TABLE t_part EXCHANGE PARTITION FOR (2) WITH TABLE t_new_part;

EXPLAIN (COSTS OFF, VERBOSE) INSERT INTO t_part VALUES (1, 5, 2, 5);
INSERT INTO t_part VALUES (1, 5, 2, 5);

EXPLAIN (COSTS OFF, VERBOSE) INSERT INTO t_part_1_prt_p2 VALUES (1, 5, 2, 5);
INSERT INTO t_part_1_prt_p2 VALUES (1, 5, 2, 5);

-- Ensure that split update on leaf and root partitions does not
-- throw partition selection error in both planners.
EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part_1_prt_p2 SET c1 = 2;
UPDATE t_part_1_prt_p2 SET c1 = 2;

EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part SET c1 = 3;
UPDATE t_part SET c1 = 3;

-- Ensure that split update on leaf partition does not throw constraint error
-- (executor does not choose the wrong partition at insert stage of update).
INSERT INTO t_part VALUES (1, 0, 2, 0);
UPDATE t_part_1_prt_p2 SET c1 = 2 WHERE c4 = 0;

SELECT count(*) FROM t_part_1_prt_p2;

-- For ORCA the partition selection error should not occur.
EXPLAIN (COSTS OFF, VERBOSE) DELETE FROM t_part_1_prt_p2;
DELETE FROM t_part_1_prt_p2;

DROP TABLE t_part;
DROP TABLE t_new_part;

-- Test split update execution of a plan from legacy planner in case
-- when parent relation has several partitions, and one of them has
-- physically-different attribute structure from parent's due to
-- dropped columns. Ensure that split update does not reconstruct tuple
-- of correct (without dropped attributes) partition.
CREATE TABLE t_part (c1 int, c2 int, c3 int, c4 int) DISTRIBUTED BY (c1)
PARTITION BY LIST (c3) (PARTITION p0 VALUES (0));

-- Legacy planner UPDATE's plan consists of several subplans (partitioned
-- relations are considered in inheritance planner), and their execution
-- order varies depending on the order the partitions have been added.
-- Therefore, we add each partition through EXCHANGE to get UPDATE's
-- test plan in a form such that the t_new_part0 update comes first, and the
-- t_new_part2 comes second. This aspect is crucial because executor's
-- partitions related logic depended on that fact, what led to the
-- issue this test demonstrates.
-- This paritition is not compatible with the parent due to dropped columns
CREATE TABLE t_new_part0 (c1 int, c11 int, c2 int, c3 int, c4 int);
ALTER TABLE t_new_part0 drop c11;
ALTER TABLE t_part EXCHANGE PARTITION FOR (0) WITH TABLE t_new_part0;

-- This partition is compatible with the parent.
ALTER TABLE t_part ADD PARTITION p2 VALUES (2);
CREATE TABLE t_new_part2 (c1 int, c2 int, c3 int, c4 int);
ALTER TABLE t_part EXCHANGE PARTITION FOR (2) WITH TABLE t_new_part2;

-- Insert into correct partition, and perform split update on root,
-- that will execute split update on each subplan in case of inheritance
-- plan (legacy planner). Ensure that split update does not reconstruct the
-- tuple at insert.
INSERT INTO t_part VALUES (1, 4, 2, 2);

EXPLAIN (COSTS OFF, VERBOSE) UPDATE t_part SET c1 = 3;
UPDATE t_part SET c1 = 3;

SELECT * FROM t_part_1_prt_p2;

DROP TABLE t_part;
DROP TABLE t_new_part0;
DROP TABLE t_new_part2;
