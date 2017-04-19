START TRANSACTION;

CREATE TABLE "payments" (
	"payment_date"      date,
	"payee"             bigint,
	"state"             char(2),
	"value"             decimal(7,2)
);

COPY INTO payments from '/tmp/data/load.csv' USING DELIMITERS ',','\n' NULL AS '';

-- ALTER TABLE "payments" ADD PRIMARY KEY ("payment_date", "payee");

COMMIT;
