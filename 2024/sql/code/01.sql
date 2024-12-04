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
CREATE TABLE lists(
    left_num int NOT NULL,
    right_num int NOT NULL
);
INSERT INTO lists
SELECT split_part(raw_input, '   ', 1)::int, split_part(raw_input, '   ', 2)::int
FROM raw_input;

WITH ranked_left AS (
	SELECT left_num, ROW_NUMBER() OVER(ORDER BY left_num) AS rank
	FROM lists
),
ranked_right AS (
	SELECT right_num, ROW_NUMBER() OVER(ORDER BY right_num) AS rank
	FROM lists
)
INSERT INTO 
    solutions(day, part, solution) 
SELECT 
    1, 'a', sum(abs(left_num - right_num)) 
FROM 
    ranked_left JOIN ranked_right USING (rank);

WITH right_counts AS (
	SELECT right_num, count(*) FROM lists GROUP BY right_num
)
INSERT INTO 
    public.solutions(DAY, part, solution) 
SELECT 
    1, 'b', SUM(l.left_num * rc.count) 
FROM 
    lists l JOIN right_counts rc ON l.left_num = rc.right_num;

--DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = 01;