SET DEFINE OFF;
DROP PACKAGE PDM_LOG.LOG_PKG;

CREATE OR REPLACE PACKAGE pdm_log.log_pkg
AS
   /******************************************************************************
      NAME:       log_pkg
      PURPOSE:    General purpose log package.

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        04/04/2017    W Reichl         1. Created this package.
   ******************************************************************************/

   -- ***********************************************************************
   --  SEE LOG_PKG_ST FOR GLOBAL PACKAGE VARIABLES USED WITH THESE LOG PROCS
   -- ***********************************************************************

   /**
    * Flexible log utility procedure that can be called with as few as one parameter.
    *
    * Pre: (Optional) log_pkg_st variables set.
    */
   PROCEDURE LOG (p_comments      VARCHAR2,
                  p_event_id      NUMBER DEFAULT NULL,
                  p_proc_name     VARCHAR2 DEFAULT NULL,
                  p_user_name     VARCHAR2 DEFAULT NULL,
                  p_table_name    VARCHAR2 DEFAULT NULL,
                  p_num_recs      NUMBER DEFAULT NULL,
                  p_error_text    VARCHAR2 DEFAULT NULL);

   PROCEDURE log_timing (p_job_group_i IN VARCHAR2, p_job_name_i IN VARCHAR2); -- { 'RUNNING', 'SUCCESS', 'FAILURE' }
END log_pkg;
/
SHOW ERRORS;


CREATE OR REPLACE SYNONYM PDM_STG.LOG_PKG FOR PDM_LOG.LOG_PKG;


CREATE OR REPLACE PUBLIC SYNONYM LOG_PKG FOR PDM_LOG.LOG_PKG;


GRANT EXECUTE ON PDM_LOG.LOG_PKG TO PDM_RPT, PDM_STG, EBIR_STG;

GRANT EXECUTE ON PDM_LOG.LOG_PKG TO PDM_STG;
