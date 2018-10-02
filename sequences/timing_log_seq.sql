SET DEFINE OFF;

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE PDM_LOG.TIMING_LOG_SEQ';
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
/

CREATE SEQUENCE pdm_log.timing_log_seq START WITH 92
                                       MAXVALUE 999999999999
                                       MINVALUE 0
                                       NOCYCLE
                                       NOCACHE
                                       NOORDER
                                       NOKEEP
                                       GLOBAL;

GRANT ALL ON pdm_log.timing_log_seq TO pdm_stg, pdm_rpt;