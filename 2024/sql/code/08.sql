--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_08 CASCADE;
CREATE SCHEMA day_08;
SET search_path TO day_08, public;

DELETE FROM public.solutions WHERE day = 08;

CREATE TABLE raw_input(
    line_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/08.txt';
\timing on

-- ACTUAL SOLUTION
CREATE TABLE antennas(
    x int,
    y int,
    frequency char,
    id SERIAL PRIMARY KEY
);
CREATE INDEX CONCURRENTLY on antennas(frequency);

WITH split_lines AS (
    SELECT 
        line_number as y,
        regexp_split_to_table(raw_input, '') as frequency
    FROM raw_input
), indexed_antennas AS(
    SELECT
        y,
        row_number() OVER(partition by y) AS x,
        frequency
    FROM split_lines
)
INSERT INTO antennas(
    SELECT x, y, frequency
    FROM indexed_antennas
    WHERE frequency != '.'
);

CREATE TABLE antinodes (
    x int,
    y int,
    frequency char,
    a1_id int,
    a2_id int,
    id SERIAL PRIMARY KEY
);


WITH antenna_pairs AS (
    SELECT 
        a1.x as x1, 
        a1.y AS y1, 
        a2.x AS x2, 
        a2.y AS y2, 
        frequency,
        a1.id AS a1_id,
        a2.id AS a2_id
    FROM antennas a1 JOIN antennas a2 USING(frequency)
    WHERE a1.id != a2.id
)
INSERT INTO antinodes
SELECT 
    x1 + (x1 - x2),
    y1 + (y1 - y2),
    frequency,
    a1_id,
    a2_id
 FROM antenna_pairs
 WHERE 
    x1 + (x1 - x2) BETWEEN 1 and 50 AND
    y1 + (y1 - y2) BETWEEN 1 and 50
;
INSERT INTO solutions
SELECT
    8, 'a', COUNT(DISTINCT (x,y)) FROM antinodes;

WITH antenna_pairs AS (
    SELECT 
        a1.x as x1, 
        a1.y AS y1, 
        a2.x AS x2, 
        a2.y AS y2, 
        frequency,
        a1.id AS a1_id,
        a2.id AS a2_id
    FROM antennas a1 JOIN antennas a2 USING(frequency)
    WHERE a1.id != a2.id
)
INSERT INTO antinodes
SELECT 
    x1 + m *(x1 - x2),
    y1 + m *(y1 - y2),
    frequency,
    a1_id,
    a2_id
 FROM antenna_pairs
    CROSS JOIN (
        SELECT generate_series(-50,50) AS m
    ) multipliers
 WHERE 
    x1 + m * (x1 - x2) BETWEEN 1 and 50 AND
    y1 + m * (y1 - y2) BETWEEN 1 and 50
;
INSERT INTO solutions
SELECT
    8, 'b', COUNT(DISTINCT (x,y)) FROM antinodes;






-- DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = 08;