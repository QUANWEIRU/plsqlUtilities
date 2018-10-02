SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
BEGIN
   demo_pkg.main ('your job group', 'your job name');
END;
/