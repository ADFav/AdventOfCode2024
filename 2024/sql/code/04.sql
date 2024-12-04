--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_04 CASCADE;
CREATE SCHEMA day_04;
SET search_path TO day_04, public;

DELETE FROM public.solutions WHERE day = 04;

CREATE TABLE raw_input(
    line_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/04.txt';
\timing on

-- ACTUAL SOLUTION
CREATE TABLE word_search_letters(
    x int,
    y int,
    letter char
);
CREATE INDEX idx_x_y ON word_search_letters (x, y);

WITH split_lines AS (
    SELECT 
        line_number, 
        regexp_split_to_table(raw_input,'') as letter
    FROM    
        raw_input
)
INSERT INTO word_search_letters
SELECT
    ROW_NUMBER() OVER(Partition by line_number),
    line_number,
    letter
FROM split_lines;

with horizontal as (
    SELECT 
        string_agg(letter, '' ORDER BY y) AS line,
        'horizontal' as direction,
        x as line_num
    FROM
        word_search_letters
    GROUP BY
        x
),
vertical as (
    SELECT 
        string_agg(letter, '' ORDER BY x)AS line,
        'vertical' as direction,
        y as line_num
    FROM
        word_search_letters
    GROUP BY
        y
), diag_1 as (
    SELECT 
        string_agg(letter, '' ORDER BY x)AS line,
        'diag_1' as direction,
        x-y as line_num
    FROM
        word_search_letters
    GROUP BY
        x - y
), diag_2 as (
    SELECT 
        string_agg(letter, '' ORDER BY x)AS line,
        'diag_2' as direction,
        x+y as line_num
    FROM
        word_search_letters
    GROUP BY
        x+y
), all_lines AS (
    SELECT * FROM horizontal
    UNION ALL
    SELECT * FROM vertical
    UNION ALL
    SELECT * FROM diag_1
    UNION ALL
    SELECT * FROM diag_2
), all_xmases AS (
    SELECT unnest(regexp_matches(line, 'XMAS','g')), direction,
    line_num
    FROM all_lines
    UNION ALL
    SELECT unnest(regexp_matches(reverse(line), 'XMAS','g')), direction,
    line_num
    FROM all_lines
)
INSERT INTO solutions
SELECT 4, 'a', count(*) FROM all_xmases;


WITH xmases AS (
	SELECT 
		wsl1.* 
	FROM 
		word_search_letters wsl1 JOIN
		word_search_letters wsl2 ON (wsl2.x, wsl2.y) = (wsl1.x - 1, wsl1.y - 1) JOIN 
		word_search_letters wsl3 ON (wsl3.x, wsl3.y) = (wsl1.x + 1, wsl1.y + 1) AND wsl3.letter != wsl2.letter JOIN 
		word_search_letters wsl4 ON (wsl4.x, wsl4.y) = (wsl1.x + 1, wsl1.y - 1) JOIN 
		word_search_letters wsl5 ON (wsl5.x, wsl5.y) = (wsl1.x - 1, wsl1.y + 1) AND wsl5.letter != wsl4.letter
	WHERE
		wsl1.letter = 'A'
		AND wsl2.letter IN ('M', 'S')
		AND wsl3.letter IN ('M', 'S')
		AND wsl4.letter IN ('M', 'S')
		AND wsl5.letter IN ('M', 'S')
)
INSERT INTO solutions
SELECT 4, 'b', COUNT(*) FROM xmases;

-- DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = 04;