-- Bank holiday prediction functions 22/03/2013 Glyn Astill <glyn@8kb.co.uk>
-- Mostly plagiarised from plpgsql functions posted to PostgreSQL mailing list
-- on 15/05/2007 by Gary Stainburn (gary.stainburn@ringways.co.uk) and converted
-- to plain sql. See:
-- 	http://www.postgresql.org/message-id/flat/200705151509.41320.gary.stainburn@ringways.co.uk#200705151509.41320.gary.stainburn@ringways.co.uk
-- 	http://www.postgresql.org/message-id/attachment/21954/bank_holidays.sql

DROP FUNCTION IF EXISTS public.calculate_easter_sunday(integer);
CREATE OR REPLACE FUNCTION public.calculate_easter_sunday(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE 
    	WHEN (((((($1%19)*19)+24)%30)+(((($1%4)*2)+(($1%7)*4)+((((($1%19)*19)+24)%30)*6)+5)%7)) < 10) THEN
    		($1 || '-03-' || (((($1%19)*19)+24)%30)+(((($1%4)*2)+(($1%7)*4)+((((($1%19)*19)+24)%30)*6)+5)%7)+22)::date
    	ELSE
    		($1 || '-04-' || (((($1%19)*19)+24)%30)+(((($1%4)*2)+(($1%7)*4)+((((($1%19)*19)+24)%30)*6)+5)%7)-9)::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_easter_sunday(integer) TO public;

--

DROP FUNCTION IF EXISTS public.calculate_new_year(integer);
CREATE OR REPLACE FUNCTION public.calculate_new_year(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE extract(dow FROM ($1 || '-01-01')::date)
    	WHEN 0 THEN ($1 || '-01-02')::date
	WHEN 6 THEN ($1 || '-01-03')::date
    	ELSE ($1 || '-01-01')::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_new_year(integer) TO public;

--

DROP FUNCTION IF EXISTS public.calculate_christmas_day(integer);
CREATE OR REPLACE FUNCTION public.calculate_christmas_day(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE extract(dow FROM ($1 || '-12-25')::date)
    	WHEN 0 THEN ($1 || '-12-27')::date
    	WHEN 6 THEN ($1 || '-12-28')::date
    	ELSE ($1 || '-12-25')::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_christmas_day(integer) TO public;
--

DROP FUNCTION IF EXISTS public.calculate_boxing_day(integer);
CREATE OR REPLACE FUNCTION public.calculate_boxing_day(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE extract(dow FROM ($1 || '-12-26')::date)
    	WHEN 0 THEN ($1 || '-12-27')::date
    	WHEN 6 THEN ($1 || '-12-28')::date
    	ELSE ($1 || '-12-26')::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_boxing_day(integer) TO public;

--

DROP FUNCTION IF EXISTS public.calculate_may_day(integer);
CREATE OR REPLACE FUNCTION public.calculate_may_day(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE 
    	WHEN extract(dow FROM ($1 || '-05-01')::date) < 2 THEN ($1 || '-05-' || 2-extract(dow FROM ($1 || '-05-01')::date))::date
    	ELSE ($1 || '-05-' || 9-extract(dow FROM ($1 || '-05-01')::date))::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_may_day(integer)  TO public;

--

DROP FUNCTION IF EXISTS public.calculate_spring_bank_holiday(integer);
CREATE OR REPLACE FUNCTION public.calculate_spring_bank_holiday(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE extract(dow FROM ($1 || '-05-31')::date)
    	WHEN 0 THEN ($1 || '-05-25')::date
    	ELSE ($1 || '-05-' || 32-extract(dow FROM ($1 || '-05-31')::date))::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_spring_bank_holiday(integer) TO public;

--

DROP FUNCTION IF EXISTS public.calculate_whitsun(integer);
CREATE OR REPLACE FUNCTION public.calculate_whitsun(integer) 
RETURNS date AS 
$BODY$    
    SELECT public.calculate_spring_bank_holiday($1) ;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_whitsun(integer)  TO public;

--

DROP FUNCTION IF EXISTS public.calculate_summer_bank_holiday(integer);
CREATE OR REPLACE FUNCTION public.calculate_summer_bank_holiday(integer) 
RETURNS date AS 
$BODY$    
    SELECT 
    CASE extract(dow FROM ($1 || '-08-31')::date)
    	WHEN 0 THEN ($1 || '-08-25')::date
    	ELSE ($1 || '-08-' || 32-extract(dow FROM ($1 || '-08-31')::date))::date
    END;
$BODY$ 
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_summer_bank_holiday(integer) TO public;

--

DROP TYPE IF EXISTS public.bank_holidays CASCADE;
CREATE TYPE public.bank_holidays AS
(year integer, description varchar, bank_holiday date);

DROP FUNCTION IF EXISTS public.calculate_bank_holidays(integer);
CREATE OR REPLACE FUNCTION public.calculate_bank_holidays(integer) 
RETURNS SETOF public.bank_holidays AS 
$BODY$
    SELECT $1, 'New Years Day', public.calculate_new_year($1)
    UNION
    SELECT $1, 'Good Friday', (public.calculate_easter_sunday($1)-'2 days'::interval)::date
    UNION
    SELECT $1, 'Easter Monday', (public.calculate_easter_sunday($1)+'1 days'::interval)::date
    UNION 
    SELECT $1, 'May Day', public.calculate_may_day($1)
    UNION 
    SELECT $1, 'Spring Bank Holiday', public.calculate_spring_bank_holiday($1)
    UNION 
    SELECT $1, 'Summer Bank Holiday', public.calculate_summer_bank_holiday($1)
    UNION 
    SELECT $1, 'Christmas Day', public.calculate_christmas_day($1)
    UNION 
    SELECT $1, 'Boxing Day', public.calculate_boxing_day($1)
    ORDER BY 3;
$BODY$
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_bank_holidays(integer) TO public;

--

DROP FUNCTION IF EXISTS public.calculate_bank_holidays(integer, integer);
CREATE OR REPLACE FUNCTION public.calculate_bank_holidays(integer, integer) 
RETURNS SETOF bank_holidays AS 
$BODY$
    SELECT (public.calculate_bank_holidays(generate_series)).* FROM generate_series($1, $2);
$BODY$
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.calculate_bank_holidays(integer, integer) TO public;

--

DROP FUNCTION IF EXISTS public.detail_bank_holiday(date);
CREATE OR REPLACE FUNCTION public.detail_bank_holiday(date) 
RETURNS SETOF bank_holidays AS 
$BODY$
    SELECT * FROM public.calculate_bank_holidays(extract(year FROM $1)::integer)
    WHERE bank_holiday = $1;
$BODY$
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.detail_bank_holiday(date) TO public;

--

DROP FUNCTION IF EXISTS public.is_bank_holiday(date);
CREATE OR REPLACE FUNCTION public.is_bank_holiday(date) 
RETURNS boolean AS 
$BODY$
    SELECT EXISTS(SELECT 1 FROM public.calculate_bank_holidays(extract(year FROM $1)::integer)
    WHERE bank_holiday = $1);
$BODY$
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.is_bank_holiday(date) TO public;

--

DROP FUNCTION IF EXISTS public.count_bank_holidays(date, date);
CREATE OR REPLACE FUNCTION public.count_bank_holidays(date, date) 
RETURNS bigint AS 
$BODY$
    SELECT count(*) FROM public.calculate_bank_holidays(extract(year FROM $1)::integer, extract(year FROM $2)::integer)
    WHERE bank_holiday BETWEEN $1 AND $2;
$BODY$
LANGUAGE SQL IMMUTABLE;

GRANT EXECUTE ON FUNCTION public.count_bank_holidays(date, date) TO public;

--