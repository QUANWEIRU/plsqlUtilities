SET DEFINE OFF;
DROP PACKAGE PDM_LOG.LOG_PKG_ST;

CREATE OR REPLACE PACKAGE pdm_log.log_pkg_st
AS
   /******************************************************************************
      NAME:       log_pkg_st
      PURPOSE:    Holds all global package variables used for logging. Using these
                  variables enables a session to call a logging procedure without
                  repeating the same parameters every time.

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        04/04/2017    W Reichl         1. Created this package.
   ******************************************************************************/

   g_event_id         pdm_log.process_log.event_id%TYPE;
   g_user_name        pdm_log.process_log.user_name%TYPE;
   g_job_id           pdm_log.timing_log.job_id%TYPE;
   g_dbms_output_on   BOOLEAN := TRUE; --defaults to true
END log_pkg_st;
/
SHOW ERRORS;


CREATE OR REPLACE SYNONYM PDM_STG.LOG_PKG_ST FOR PDM_LOG.LOG_PKG_ST;


CREATE OR REPLACE PUBLIC SYNONYM LOG_PKG_ST FOR PDM_LOG.LOG_PKG_ST;


GRANT EXECUTE ON PDM_LOG.LOG_PKG_ST TO PDM_STG, PDM_RPT, EBIR_STG;
