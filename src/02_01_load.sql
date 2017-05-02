START TRANSACTION;

CREATE TABLE "payments" (
	"state"             char(2),
	"p_date"            date,
	"payee"             bigint,
	"value"             decimal(7,2),
	"log_value"         decimal(18,16)
);

COPY INTO payments from '/tmp/data/load.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
