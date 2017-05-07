CREATE REMOTE TABLE t@YEAR@ (state char(2), p_date date, payee bigint, value decimal(7,2), log_value decimal(18,16)) on 'mapi:monetdb://monetdb-@YEAR@:50000/db';
ALTER TABLE payments ADD TABLE t@YEAR@;
