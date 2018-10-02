SET DEFINE OFF

CREATE OR REPLACE PACKAGE pdm_log.demo_pkg
IS
   PROCEDURE main (p_job_group_i IN VARCHAR2, p_job_name_i IN VARCHAR2, p_fail_i in char default 'N');
END demo_pkg;
/

SHOW ERRORS;