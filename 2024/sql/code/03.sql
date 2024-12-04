--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_?? CASCADE;
CREATE SCHEMA day_??;
SET search_path TO day_??, public;

DELETE FROM public.solutions WHERE day = ??;
INSERT INTO public.solutions(day, part) VALUES (??, 'a'), (??, 'b');

CREATE TABLE raw_input(
    row_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/??.txt';


-- ACTUAL SOLUTION
WITH muls AS (
SELECT
	UNNEST(
        regexp_matches( 
            raw_input,
	        'mul\(\d{1,3},\d{1,3}\)',
	        'g'
        )
    ) AS mul
FROM
	raw_input 
),
multiplicand_arrays AS(
SELECT
	regexp_matches(
        mul,
	    'mul\((\d{1,3}),(\d{1,3})\)'
    ) AS multiplicands
FROM
	muls
)
INSERT INTO solutions
SELECT
    3,'a',sum(multiplicands[1]::int * multiplicands[2]::int)
FROM
	multiplicand_arrays
;

WITH statements AS (
SELECT
	REGEXP_SPLIT_TO_TABLE(
        string_agg(
            raw_input,
	        ''
        ),
	    '(do\(\)|don''t\(\))'
    ) AS statement
FROM
	raw_input
), numbered_statements AS (
SELECT
	ROW_NUMBER() OVER() AS statement_num,
	statement
FROM
	statements
), dos_and_donts AS (
SELECT
	UNNEST(
        regexp_matches(
            raw_input,
	        '(do\(\)|don''t\(\))',
	        'g'
        )
    ) AS do_dont
FROM
	raw_input
), numbered_dos_and_donts AS (
SELECT
	ROW_NUMBER() OVER() AS do_dont_num,
	do_dont
FROM
	dos_and_donts
), muls AS (
SELECT
	UNNEST(
        regexp_matches(
            statement,
	        'mul\(\d{1,3},\d{1,3}\)',
	        'g'
        )
    ) AS mul
FROM
	numbered_Statements
LEFT OUTER JOIN numbered_dos_and_donts ON
	do_dont_num + 1 = statement_num
WHERE 
	do_dont = 'do()'
	OR do_dont IS NULL
), multiplicand_arrays AS(
SELECT
	regexp_matches(
        mul,
	    'mul\((\d{1,3}),(\d{1,3})\)'
    ) AS multiplicands
FROM
	muls
)
INSERT INTO solutions
SELECT 
    3, 'b', sum(multiplicands[1]::int * multiplicands[2]::int)
FROM
	multiplicand_arrays
;

-- DISPLAY SOLUTION
SELECT * FROM solutions WHERE DAY = 03;