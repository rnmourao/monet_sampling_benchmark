CREATE REMOTE TABLE t@YEAR@ (state char(2), p_date date, payee bigint, value decimal(7,2), newcomer tinyint, freshout tinyint, id int) on 'mapi:monetdb://monetdb-@YEAR@:50000/db';
ALTER TABLE payments ADD TABLE t@YEAR@;
