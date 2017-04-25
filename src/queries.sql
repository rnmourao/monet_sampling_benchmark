CREATE FUNCTION amostra(pdate date, st char(2)) RETURNS TABLE(v decimal(7, 2))
BEGIN
   RETURN SELECT value FROM payments WHERE payment_date = pdate AND state = st SAMPLE 400;
END;

select * from amostra('2011-01-01', 'DF');
