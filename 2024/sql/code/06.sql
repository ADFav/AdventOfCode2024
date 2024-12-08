--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_06 CASCADE;
CREATE SCHEMA day_06;
SET search_path TO day_06, public;

DELETE FROM public.solutions WHERE day = 06;

CREATE TABLE raw_input(
    line_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/06.txt';
\timing on

-- ACTUAL SOLUTION
CREATE TABLE impediments(
    x int,
    y int
);

WITH split_lines AS (
SELECT
	line_number,
	regexp_split_to_table(raw_input,'') AS position
FROM
	raw_input
), impediment_positions AS (
SELECT
	ROW_NUMBER() OVER (PARTITION BY line_number) AS x,
	line_number AS y,
	position
FROM
	split_lines
ORDER BY
	line_number
)
INSERT INTO impediments
SELECT
	x,	y
FROM
	impediment_positions
WHERE 
    position = '#';

CREATE TABLE starting_position(
    x int,
    y int
);
WITH split_lines AS (
SELECT
	line_number,
	regexp_split_to_table(raw_input,'') AS position
FROM
	raw_input
), impediment_positions AS (
SELECT
	ROW_NUMBER() OVER (PARTITION BY line_number) AS x,
	line_number AS y,
	position
FROM
	split_lines
ORDER BY
	line_number
)
INSERT INTO starting_position
SELECT
	x,	y
FROM
	impediment_positions
WHERE 
    position = '^';

CREATE TABLE rotations(
    starting_direction text primary key,
    rotated_direction text
);
INSERT INTO rotations VALUES 
    ('up', 'right'),
    ('right', 'down'),
    ('down', 'left'),
    ('left', 'up')
;
CREATE INDEX CONCURRENTLY idx_impediments_x_y  ON impediments(x,y) ;

CREATE TABLE paths(
    start_x int,
    start_y int,
    end_x int,
    end_y int,
    id serial primary key
);
INSERT INTO paths
    SELECT 
        x, 
        y, 
        COALESCE(LEAD(x) OVER (PARTITION BY y ORDER BY x),130 + 1),
        y
    FROM impediments
    UNION ALL
    SELECT
        x,
        y,
        x,
        COALESCE(LEAD(y) OVER (PARTITION BY x ORDER BY y), 130 + 1)
    FROM impediments
    UNION ALL
    SELECT DISTINCT ON (y)
        COALESCE(LAG(x) OVER (PARTITION BY y ORDER BY x), 0),
        y, 
        x, 
        y
    FROM impediments 
    UNION ALL
    SELECT DISTINCT ON (x)
        x,
        COALESCE(LAG(y) OVER (PARTITION BY x ORDER BY y), 0),
        x,
        y
    FROM impediments
    ORDER BY 
    x DESC --, y DESC;
  ;  
CREATE INDEX concurrently paths_start_x_end_x ON paths(start_x, end_x);
CREATE INDEX concurrently paths_start_y_end_y ON paths(start_y, end_y);

CREATE TABLE original_path_positions (
    x int,
    y int
);

WITH RECURSIVE traveled_paths AS (
    SELECT
        'up' AS direction,
        -- p.id AS path_id,
        sp.x AS starting_x,
        sp.y AS starting_y,
        p.start_x AS ending_x,
        p.start_y + 1 AS ending_y
    FROM
        paths p JOIN starting_position sp ON 
            sp.x BETWEEN p.start_x and p.end_x AND
            sp.y BETWEEN p.start_y and p.end_y
            AND p.start_x = p.end_x
    UNION
    SELECT
        r.rotated_direction AS direction,
        -- p.id AS path_id,
        tp.ending_x,
        tp.ending_y,
        CASE r.rotated_direction
            WHEN 'right' THEN p.end_x - 1
            WHEN 'left' THEN p.start_x + 1
            ELSE p.end_x
        END AS ending_x,
        CASE r.rotated_direction
            WHEN 'up' THEN p.start_y + 1
            WHEN 'down' THEN p.end_y - 1
            ELSE p.end_y
        END AS ending_y
        FROM 
            traveled_paths tp
            JOIN rotations r ON tp.direction = r.starting_direction 
            JOIN paths p ON CASE r.rotated_direction
                WHEN 'right' THEN p.start_y = p.end_y
                WHEN 'left' THEN p.start_y = p.end_y 
                WHEN 'up' THEN p.start_x = p.end_x 
                WHEN 'down' THEN p.start_x = p.end_x
            END 
            AND tp.ending_x BETWEEN p.start_x and p.end_x
            AND tp.ending_y BETWEEN p.start_y and p.end_y
        WHERE 
            CASE tp.direction
                WHEN 'up' THEN p.start_y > 1
                WHEN 'down' THEN p.end_y < 130 
                WHEN 'left' THEN p.start_x > 1
                WHEN 'right' THEN p.end_X < 130
            END
)
INSERT INTO original_path_positions
SELECT 
    generate_series(least(starting_x, ending_x), greatest(starting_x, ending_x)) AS x, 
    starting_y AS y
FROM traveled_paths
WHERE 
    direction IN ('left','right')
UNION 
SELECT
    starting_x AS x,
    generate_series(least(starting_y, ending_y), greatest(starting_y, ending_y)) AS y
FROM traveled_paths
WHERE 
    direction in ('up','down')
;

INSERT INTO solutions
SELECT 6, 'a', count(*) 
FROM original_path_positions;

CREATE TABLE hypothetical_paths(
    new_impediment_x int,
    new_impediment_y int,
    start_x int,
    start_y int,
    end_x int,
    end_y int
);
INSERT INTO hypothetical_paths
SELECT DISTINCT ON (op.x, op.y)
    x,
    y,
    x, 
    y, 
    COALESCE(p.start_x, 130 + 1),
    y
FROM original_path_positions op 
LEFT JOIN paths p ON p.start_x > op.x and p.start_y = op.y and p.end_y = op.y;
 
INSERT INTO hypothetical_paths
SELECT DISTINCT ON (op.x, op.y)
    x,
    y,
    x,
    y,
    x,
    COALESCE(p.start_y, 130 + 1)
FROM original_path_positions op 
LEFT JOIN paths p ON p.start_y > op.y and p.start_x = op.x and p.end_x = op.x;

INSERT INTO hypothetical_paths
SELECT DISTINCT ON (op.x, op.y)
    x,
    y,
    COALESCE(p.end_x, 0),
    y, 
    x, 
    y
FROM original_path_positions op 
LEFT JOIN paths p ON p.end_x < op.x and p.start_y = op.y and p.end_y = op.y;

INSERT INTO hypothetical_paths
SELECT DISTINCT ON (op.x, op.y)
    x,
    y,
    x,
    COALESCE(p.end_y, 0),
    x,
    y
FROM original_path_positions op 
LEFT JOIN paths p ON p.end_y < op.y and p.start_x = op.x and p.end_x = op.x;

CREATE INDEX idx_hp ON hypothetical_paths(new_impediment_x, new_impediment_y);--, start_x, end_x, start_y, end_y);
CREATE INDEX idx_hp_2 ON hypothetical_paths(start_x, end_x, start_y, end_y);

WITH RECURSIVE traveled_paths AS (
    SELECT
        op.x AS op_x,
        op.y AS op_y,
        'up' AS direction,
        p.id AS path_id,
        sp.x AS starting_x,
        sp.y AS starting_y,
        COALESCE(hp.start_x, p.start_x) AS ending_x,
        COALESCE(hp.start_y, p.start_y) + 1 AS ending_y,
        FALSE AS is_exit,
        '***',
        p.start_x AS p_start_x,
        p.start_y AS p_start_y,
        p.end_x AS p_end_x,
        p.end_y AS p_end_y,
        '***',
        hp.end_x AS hp_end_x,
        hp.end_y AS hp_end_y
    FROM
        paths p 
        CROSS JOIN original_path_positions op
        JOIN starting_position sp ON 
            sp.x BETWEEN p.start_x and p.end_x AND
            sp.y BETWEEN p.start_y and p.end_y
            AND p.start_x = p.end_x
        LEFT JOIN hypothetical_paths hp ON (op.x, op.y) = (hp.new_impediment_x, hp.new_impediment_y) AND
            sp.x BETWEEN hp.start_x and hp.end_x AND
            sp.y BETWEEN hp.start_y and hp.end_y
            AND hp.start_x = hp.end_x  
    WHERE
        (op.x, op.y) != (sp.x, sp.y)
    UNION
    SELECT
        op_x,
        op_y,
        r.rotated_direction AS direction,
        p.id AS path_id,
        tp.ending_x,
        tp.ending_y,
        CASE r.rotated_direction
            WHEN 'right'    THEN COALESCE(hp.end_x - 1,     p.end_x - 1,    130)
            WHEN 'left'     THEN COALESCE(hp.start_x + 1,   p.start_x + 1,  0)
            ELSE tp.ending_x
        END AS ending_x,
        CASE r.rotated_direction
            WHEN 'down'     THEN COALESCE(hp.end_y - 1,     p.end_y - 1,    130)
            WHEN 'up'       THEN COALESCE(hp.start_y + 1,   p.start_y + 1,  0)
            ELSE tp.ending_y
        END AS ending_y,
        CASE r.rotated_direction
            WHEN 'up'       THEN COALESCE(hp.start_y + 1,   p.start_y + 1,  0)   <= 0
            WHEN 'down'     THEN COALESCE(hp.end_y - 1,     p.end_y - 1,    130) >= 130
            WHEN 'left'     THEN COALESCE(hp.start_x + 1,   p.start_x + 1,  0)   <= 0
            WHEN 'right'    THEN COALESCE(hp.end_x - 1,     p.end_x - 1,    130) >= 130
        END AS is_exit,
        '***',
        p.start_x AS p_start_x,
        p.start_y AS p_start_y,
        p.end_x AS p_end_x,
        p.end_y AS p_end_y,
        '***',
        hp.end_x AS hp_end_x,
        hp.end_y AS hp_end_y
        FROM 
            traveled_paths tp
            JOIN rotations r ON tp.direction = r.starting_direction 
            LEFT JOIN paths p ON CASE r.rotated_direction
                WHEN 'right'    THEN p.start_y = p.end_y
                WHEN 'left'     THEN p.start_y = p.end_y 
                WHEN 'up'       THEN p.start_x = p.end_x 
                WHEN 'down'     THEN p.start_x = p.end_x
            END 
            AND tp.ending_x BETWEEN p.start_x and p.end_x
            AND tp.ending_y BETWEEN p.start_y and p.end_y
            LEFT JOIN hypothetical_paths hp ON CASE r.rotated_direction
                WHEN 'right'    THEN hp.start_y = hp.end_y
                WHEN 'left'     THEN hp.start_y = hp.end_y 
                WHEN 'up'       THEN hp.start_x = hp.end_x 
                WHEN 'down'     THEN hp.start_x = hp.end_x
            END 
            AND (op_x, op_y) = (hp.new_impediment_x, hp.new_impediment_y)
            AND tp.ending_x BETWEEN hp.start_x and hp.end_x
            AND tp.ending_y BETWEEN hp.start_y and hp.end_y
        WHERE 
            not tp.is_exit
), is_exits AS (
SELECT op_x, op_y
FROM traveled_paths
GROUP BY op_x, op_y
HAVING every(not is_exit)
)
INSERT INTO solutions
SELECT 6, 'b', COUNT(*)
FROM is_exits;






-- DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = 06;