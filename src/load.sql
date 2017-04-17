START TRANSACTION;

CREATE TABLE "payments" (
	"state"             char(2),
	"payment_date"      date,
	"payee"             bigint,
	"value"             decimal(7,2)
);

COPY INTO payments from '/tmp/load.csv' USING DELIMITERS ',','\n' NULL AS '';

ALTER TABLE "payments" ADD PRIMARY KEY ("state", "payment_date");

COMMIT;
