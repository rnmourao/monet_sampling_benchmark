START TRANSACTION;

CREATE TABLE "T@YEAR@" (
	"state"             char(2),
	"p_date"            date,
	"payee"             bigint,
	"value"             decimal(7,2),
	"log_value"         decimal(18,16)
);

COPY INTO "T@YEAR@" from '/tmp/data/@YEAR@.csv' USING DELIMITERS ',','\n' NULL AS '';

COMMIT;
