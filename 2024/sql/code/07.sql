--BOILERPLATE
CREATE TABLE IF NOT EXISTS public.solutions(
    day int,
    part text,
    solution text
) ;
DROP SCHEMA IF EXISTS day_07 CASCADE;
CREATE SCHEMA day_07;
SET search_path TO day_07, public;

DELETE FROM public.solutions WHERE day = 07;

CREATE TABLE raw_input(
    line_number SERIAL,
    raw_input text
);
COPY raw_input (raw_input) FROM '/input/07.txt';
\timing on

-- ACTUAL SOLUTION

CREATE TABLE equation_operands(
    equation_number int,
    target_value bigint,
    operand_index int,
    operand bigint
);
WITH equations_parts AS (
    SELECT 
        line_number as equation_number,
        regexp_split_to_array(raw_input, ':\s+') as parts
    FROM raw_input
), operands AS (
    SELECT
        equation_number,
        parts[1]::bigint AS target_value,
        regexp_split_to_table(parts[2],'\s+')::bigint as operand
    FROM equations_parts
)
INSERT INTO equation_operands
SELECT 
    equation_number,
    target_value,
    ROW_NUMBER() OVER(PARTITION BY equation_number),
    operand
FROM operands;

CREATE TABLE operations(
    operation char
);
INSERT INTO operations VALUES
('*'), ('+');

WITH RECURSIVE evaluations AS (
    SELECT 
        op1.equation_number,
        op1.target_value,
        op2.operand_index,
        op1.operand,
        o.operation,
        op2.operand,
        CASE o.operation
            WHEN '*' THEN op1.operand * op2.operand
            WHEN '+' THEN op1.operand + op2.operand
        END as result
    FROM
        equation_operands op1 
        JOIN equation_operands op2 ON 
            op1.equation_number = op2.equation_number 
            AND op2.operand_index = op1.operand_index + 1
        CROSS JOIN operations o
    WHERE op1.operand_index = 1
    UNION
    SELECT
        e.equation_number,
        e.target_value,
        op.operand_index,
        e.result,
        o.operation,
        op.operand,
        CASE o.operation
            WHEN '*' THEN e.result * op.operand
            WHEN '+' THEN e.result + op.operand
        END as result
    FROM
        evaluations e 
        JOIN equation_operands op ON 
            e.equation_number = op.equation_number 
            AND op.operand_index = e.operand_index + 1
        CROSS JOIN operations o
    WHERE
        result <= e.target_value
), valid_equations AS (
    SELECT DISTINCT ON (equation_number) 
        result 
    FROM evaluations
    WHERE result = target_value
)
INSERT INTO solutions
SELECT 7, 'a', sum(result) FROM valid_equations;


INSERT INTO operations VALUES ('|');

WITH RECURSIVE evaluations AS (
    SELECT 
        op1.equation_number,
        op1.target_value,
        op2.operand_index,
        op1.operand,
        o.operation,
        op2.operand,
        CASE o.operation
            WHEN '*' THEN op1.operand * op2.operand
            WHEN '+' THEN op1.operand + op2.operand
            WHEN '|' THEN (op1.operand::text || op2.operand::text)::bigint
        END as result
    FROM
        equation_operands op1 
        JOIN equation_operands op2 ON 
            op1.equation_number = op2.equation_number 
            AND op2.operand_index = op1.operand_index + 1
        CROSS JOIN operations o
    WHERE op1.operand_index = 1
    UNION
    SELECT
        e.equation_number,
        e.target_value,
        op.operand_index,
        e.result,
        o.operation,
        op.operand,
        CASE o.operation
            WHEN '*' THEN e.result * op.operand
            WHEN '+' THEN e.result + op.operand
            WHEN '|' THEN (e.result::text || op.operand::text)::bigint
        END as result
    FROM
        evaluations e 
        JOIN equation_operands op ON 
            e.equation_number = op.equation_number 
            AND op.operand_index = e.operand_index + 1
        CROSS JOIN operations o
    WHERE
        result <= e.target_value
), valid_equations AS (
    SELECT DISTINCT ON (equation_number) 
        result 
    FROM evaluations
    WHERE result = target_value
)
INSERT INTO solutions
SELECT 7, 'b', sum(result) FROM valid_equations;


-- DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = 07;