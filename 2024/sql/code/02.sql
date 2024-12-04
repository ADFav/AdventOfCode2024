--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_02 CASCADE;
CREATE SCHEMA day_02;
SET search_path TO day_02, public;

DELETE FROM public.solutions WHERE day = 02;

CREATE TABLE raw_input(
    line_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/02.txt';
\timing on

-- ACTUAL SOLUTION

CREATE TABLE reports (
    report_number int,
    level_value int,
    level_id SERIAL PRIMARY KEY
);

INSERT INTO reports
SELECT
    line_number,
    regexp_split_to_table(raw_input, '\s+')::int AS LEVEL
FROM
    raw_input;

CREATE TABLE report_deltas(
    report_number int,
    level_id int primary key,
    level_value int,
    next_value int,
    valid_increase boolean,
    valid_decrease boolean
);

INSERT INTO report_deltas
SELECT
    r1.report_number,
    r1.level_id,
    r1.level_value,
    r2.level_value,
    COALESCE(r2.level_value - r1.level_value BETWEEN 1 and 3, TRUE) as valid_increase,
    COALESCE(r1.level_value - r2.level_value BETWEEN 1 and 3, TRUE) as valid_decrease
FROM
    reports r1 LEFT OUTER JOIN 
    reports r2 ON (r2.level_id, r2.report_number) = (r1.level_id + 1, r1.report_number)
ORDER BY 
    r1.level_id;

WITH safe_reports AS (
    SELECT 
        report_number 
    FROM report_deltas
    GROUP BY report_number
    HAVING every(valid_increase) or every(valid_decrease)
)
INSERT INTO solutions
SELECT 2, 'a', count(*) FROM safe_reports;

CREATE TABLE report_skips(
    report_number int,
    level_id int,
    level_value int,
    skipped_id int,
    report_skip_id SERIAL PRIMARY KEY
);

INSERT INTO report_skips
SELECT
    r1.report_number,
    r1.level_id,
    r1.level_value,
    r2.level_id
FROM
    reports r1 JOIN 
    reports r2 ON r1.report_number = r2.report_number AND r1.level_id != r2.level_id
ORDER BY r1.report_number, r2.level_id, r1.level_id;

CREATE TABLE report_skip_deltas(
    report_number int,
    skipped_id int,
    level_value int,
    next_value int,
    valid_increase boolean,
    valid_decrease boolean
);

INSERT INTO report_skip_deltas
SELECT
    rs1.report_number,
    rs1.skipped_id,
    rs1.level_value,
    rs2.level_value,
    COALESCE(rs2.level_value - rs1.level_value BETWEEN 1 and 3, TRUE) as valid_increase,
    COALESCE(rs1.level_value - rs2.level_value BETWEEN 1 and 3, TRUE) as valid_decrease
FROM
    report_skips rs1 LEFT OUTER JOIN
    report_skips rs2 ON (rs2.skipped_id, rs2.report_skip_id) = (rs1.skipped_id, rs1.report_skip_id + 1);

WITH safe_reports AS (
    SELECT 
        report_number 
    FROM report_deltas
    GROUP BY report_number
    HAVING every(valid_increase) or every(valid_decrease)
),
safe_skip_reports AS (
    SELECT DISTINCT ON (report_number)
        report_number
    FROM
        report_skip_deltas
    GROUP BY
        report_number, skipped_id
    HAVING EVERY(valid_increase) OR EVERY(valid_decrease)
),
all_safe_reports AS (
    SELECT * FROM safe_reports UNION SELECT * FROM safe_skip_reports

)
INSERT INTO solutions
SELECT 2, 'b', count(*) FROM all_safe_reports;

-- DISPLAY SOLUTION
SELECT * FROM solutions WHERE day = 02;