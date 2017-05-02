START TRANSACTION;

CREATE TABLE "payments" (
	"payee"             bigint,
	"p_date"            date,
	"state"             char(2),
	"value"             decimal(7,2),
	"log_value"         decimal(7,2)
);

COPY INTO payments from '/tmp/data/load.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
