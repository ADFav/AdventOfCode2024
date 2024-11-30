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






-- DISPLAY SOLUTION
SELECT * FROM public.solutions WHERE day = ??;