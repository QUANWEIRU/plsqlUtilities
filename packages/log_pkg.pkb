SET DEFINE OFF;
DROP PACKAGE BODY pdm_log.log_pkg;

CREATE OR REPLACE PACKAGE BODY pdm_log.log_pkg
AS
   FUNCTION get_subproc (p_owner_i VARCHAR2, p_pkgname_i VARCHAR2, p_line_no_i NUMBER)
      RETURN VARCHAR2
   IS
      v_subproc   VARCHAR2 (50);
   BEGIN
      BEGIN
         --
         -- If not supplied, attempt to pull subproc name from all_source view by source code line.
         -- Strip out everything including/after the first semi-colon or left paren
         -- Trim and make upper case
         --
         SELECT REGEXP_REPLACE (MAX (REGEXP_SUBSTR (UPPER (s.text),
                                                    '[^ (]+',
                                                    1,
                                                    2)) -- attempt to pull second word, split on space/left paren
                                KEEP (DENSE_RANK LAST ORDER BY s.line) -- combined with MAX
                                                                      ,
                                '[[:space:]]',
                                '') -- remove trailing newline character
                   AS subproc
           INTO v_subproc
           FROM dba_source s
          WHERE     s.owner = p_owner_i
                AND s.name = p_pkgname_i
                AND s.TYPE = 'PACKAGE BODY'
                AND s.line < p_line_no_i
                AND REGEXP_LIKE (TRIM (UPPER (s.text)), '^(PROCEDURE)|(FUNCTION)');
      EXCEPTION
         WHEN OTHERS --this expression won't be foolproof, dont want to throw hard exception under any circumstances
         THEN
            v_subproc := NULL;
      END;

      RETURN v_subproc;
   END get_subproc;

   /**
   * Write entry to internal IT support log These entries will not be displayed anywhere
   * in the application, and will have a shorter retention period.
   *
   * Also, log_internal is an autonomous procedure, so logged lines are preserved even after the main
   * transaction rolls back.
   */
   PROCEDURE log_old (p_comments       VARCHAR2,
                      p_event_id       NUMBER DEFAULT NULL,
                      p_proc_name      VARCHAR2 DEFAULT NULL,
                      p_user_name      VARCHAR2 DEFAULT NULL,
                      p_table_name     VARCHAR2 DEFAULT NULL,
                      p_num_recs       NUMBER DEFAULT NULL,
                      p_error_text     VARCHAR2 DEFAULT NULL,
                      p_owner          VARCHAR2,
                      p_caller_name    VARCHAR2,
                      p_lineno         NUMBER,
                      p_caller_type    VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_error_text    process_log.ERROR_TEXT%TYPE;
      v_owner         VARCHAR2 (100);
      v_name          VARCHAR2 (100);
      v_lineno        NUMBER;
      v_caller_type   VARCHAR2 (100);
      v_subproc       VARCHAR2 (200);
   BEGIN
      OWA_UTIL.who_called_me (v_owner,
                              v_name,
                              v_lineno,
                              v_caller_type);

      IF p_caller_type = 'PACKAGE BODY' AND p_proc_name IS NULL
      THEN
         v_subproc := get_subproc (p_owner, p_caller_name, p_lineno);
      END IF;

      IF SQLCODE <> 0 OR p_error_text IS NOT NULL
      THEN
         v_error_text :=
            SQLERRM || '. ERROR TRACE: ' || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO process_log (log_timestamp,
                                  event_id,
                                  own_name,
                                  pkg_name,
                                  proc_name,
                                  line_nbr,
                                  user_name,
                                  table_name,
                                  num_recs,
                                  comments,
                                  ERROR_TEXT)
                 VALUES (
                           CURRENT_TIMESTAMP,
                           NVL (p_event_id, log_pkg_st.g_event_id),
                           p_owner,
                           p_caller_name,
                           NVL (p_proc_name, v_subproc),
                           p_lineno,
                           NVL (p_user_name, USER),
                           p_table_name,
                           p_num_recs,
                           SUBSTR (p_comments, 1, 4000),
                           SUBSTR (
                                 DECODE (p_error_text, NULL, NULL, p_error_text || ' : ')
                              || v_error_text,
                              1,
                              4000));
      ELSE
         INSERT INTO process_log (log_timestamp,
                                  event_id,
                                  own_name,
                                  pkg_name,
                                  proc_name,
                                  line_nbr,
                                  user_name,
                                  table_name,
                                  num_recs,
                                  comments,
                                  ERROR_TEXT)
              VALUES (CURRENT_TIMESTAMP,
                      NVL (p_event_id, log_pkg_st.g_event_id),
                      p_owner,
                      p_caller_name,
                      NVL (p_proc_name, v_subproc), --NVL (p_proc_name, log_pkg_st.g_proc_name),
                      p_lineno,
                      NVL (p_user_name, USER),
                      p_table_name,
                      p_num_recs,
                      SUBSTR (p_comments, 1, 4000),
                      NULL);
      END IF;

      COMMIT;
   END log_old;

   /**
   * Write entry to internal IT support log DPF_IT_LOG. These entries will not be displayed anywhere
   * in the application, and will have a shorter retention period.
   *
   * Also, log_internal is an autonomous procedure, so logged lines are preserved even after the main
   * transaction rolls back.
   */
   PROCEDURE log_new (p_comments       VARCHAR2,
                      p_event_id       NUMBER DEFAULT NULL,
                      p_proc_name      VARCHAR2 DEFAULT NULL,
                      p_user_name      VARCHAR2 DEFAULT NULL,
                      p_table_name     VARCHAR2 DEFAULT NULL,
                      p_num_recs       NUMBER DEFAULT NULL,
                      p_error_text     VARCHAR2 DEFAULT NULL,
                      p_owner          VARCHAR2,
                      p_caller_name    VARCHAR2,
                      p_lineno         NUMBER,
                      p_caller_type    VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_error_text   process_log.ERROR_TEXT%TYPE;
      v_subproc      VARCHAR2 (200);
      v_pkg_name     VARCHAR2 (100);
   BEGIN
      IF p_caller_type = 'PACKAGE BODY' AND p_proc_name IS NULL
      THEN
         v_pkg_name :=
            regexp_substr (p_caller_name,
                           '[^\.]+',
                           1,
                           1);
         v_subproc :=
            regexp_substr (p_caller_name,
                           '[^\.]+',
                           1,
                           2);
      END IF;

      IF SQLCODE <> 0 OR p_error_text IS NOT NULL
      THEN
         v_error_text :=
            SQLERRM || '. ERROR TRACE: ' || DBMS_UTILITY.format_error_backtrace;

         INSERT INTO process_log (log_timestamp,
                                  event_id,
                                  own_name,
                                  pkg_name,
                                  proc_name,
                                  line_nbr,
                                  user_name,
                                  table_name,
                                  num_recs,
                                  comments,
                                  ERROR_TEXT)
                 VALUES (
                           CURRENT_TIMESTAMP,
                           NVL (p_event_id, log_pkg_st.g_event_id),
                           p_owner,
                           NVL (v_pkg_name, p_caller_name), --v_caller_name used for standalone procs, etc
                           NVL (p_proc_name, v_subproc),
                           p_lineno,
                           NVL (p_user_name, USER),
                           p_table_name,
                           p_num_recs,
                           SUBSTR (p_comments, 1, 4000),
                           SUBSTR (
                                 DECODE (p_error_text, NULL, NULL, p_error_text || ' : ')
                              || v_error_text,
                              1,
                              4000));
      ELSE
         INSERT INTO process_log (log_timestamp,
                                  event_id,
                                  own_name,
                                  pkg_name,
                                  proc_name,
                                  line_nbr,
                                  user_name,
                                  table_name,
                                  num_recs,
                                  comments,
                                  ERROR_TEXT)
              VALUES (CURRENT_TIMESTAMP,
                      NVL (p_event_id, log_pkg_st.g_event_id),
                      p_owner,
                      NVL (v_pkg_name, p_caller_name), --v_caller_name used for standalone procs, etc
                      NVL (p_proc_name, v_subproc), --NVL (p_proc_name, log_pkg_st.g_proc_name),
                      p_lineno,
                      NVL (p_user_name, USER),
                      p_table_name,
                      p_num_recs,
                      SUBSTR (p_comments, 1, 4000),
                      NULL);
      END IF;

      COMMIT;
   END log_new;

   /**
   * Write entry to internal IT support. These entries will not be displayed anywhere
   * in the application, and will have a shorter retention period.
   *
   * Also, log_internal is an autonomous procedure, so logged lines are preserved even after the main
   * transaction rolls back.
   *
   * 11/27/2017 -- With upgrade to 12.2, there were changes to the behavior of SYS.OWA_UTIL.WHO_CALLED_ME,
   *   now returning the package AND PROCEDURE, instead of just the package. This procedure now becomes a
   *   wrapper around two new procedures, LOG_OLD (same as old "LOG" procedure) and LOG_NEW, which will
   *   determine PKG_NAME and PROC_NAME using a new, appropriate method.
   */
   PROCEDURE LOG (p_comments      VARCHAR2,
                  p_event_id      NUMBER DEFAULT NULL,
                  p_proc_name     VARCHAR2 DEFAULT NULL,
                  p_user_name     VARCHAR2 DEFAULT NULL,
                  p_table_name    VARCHAR2 DEFAULT NULL,
                  p_num_recs      NUMBER DEFAULT NULL,
                  p_error_text    VARCHAR2 DEFAULT NULL)
   IS
      v_db_release         v$instance.version%TYPE;
      v_db_major_version   NUMBER;
      v_db_minor_version   NUMBER;
      v_owner              VARCHAR2 (100);
      v_caller_name        VARCHAR2 (100);
      v_lineno             NUMBER;
      v_caller_type        VARCHAR2 (100);
   BEGIN
      OWA_UTIL.who_called_me (v_owner,
                              v_caller_name,
                              v_lineno,
                              v_caller_type);

      SELECT version INTO v_db_release FROM v$instance;

      --e.g. 12.2.0.1.0, pull first group of characters != ".", in this case, "12", then convert to number
      v_db_major_version :=
         to_number (regexp_substr (v_db_release,
                                   '[^\.]+',
                                   1,
                                   1));
      --e.g. 12.2.0.1.0, pull second group of characters != ".", in this case, "2", then convert to number
      v_db_minor_version :=
         to_number (regexp_substr (v_db_release,
                                   '[^\.]+',
                                   1,
                                   2));

      IF v_db_major_version > 12 OR (v_db_major_version = 12 AND v_db_minor_version >= 2)
      THEN
         log_new (p_comments,
                  p_event_id,
                  p_proc_name,
                  p_user_name,
                  p_table_name,
                  p_num_recs,
                  p_error_text,
                  v_owner,
                  v_caller_name,
                  v_lineno,
                  v_caller_type);
      ELSE
         log_old (p_comments,
                  p_event_id,
                  p_proc_name,
                  p_user_name,
                  p_table_name,
                  p_num_recs,
                  p_error_text,
                  v_owner,
                  v_caller_name,
                  v_lineno,
                  v_caller_type);
      END IF;
   END LOG;

   PROCEDURE log_timing (p_job_group_i IN VARCHAR2, p_job_name_i IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_owner         VARCHAR2 (36);
      v_name          VARCHAR2 (36);
      v_lineno        NUMBER;
      v_caller_type   VARCHAR2 (30);
      v_status        timing_log.status%TYPE;
      v_subproc       VARCHAR2 (50);
   BEGIN
      OWA_UTIL.who_called_me (v_owner,
                              v_name,
                              v_lineno,
                              v_caller_type);

      v_subproc := get_subproc (v_owner, v_name, v_lineno);

      IF log_pkg_st.g_job_id IS NULL --theoretically you could override with a preferred ID, something from Control-M, etc...just needs to be unique
      THEN
         log_pkg_st.g_job_id := timing_log_seq.nextVal;
      END IF;

      IF log_pkg_st.g_event_id IS NULL
      THEN
         log_pkg_st.g_event_id := log_pkg_st.g_job_id; --sets EVENT_ID for Process_Log to match job ID
      END IF;

      IF SQLCODE <> 0
      THEN
         v_status := 'FAILURE';
      ELSE
         v_status := 'SUCCESS';
      END IF;

      MERGE INTO pdm_log.timing_log tl
           USING (SELECT log_pkg_st.g_job_id         AS job_id,
                         p_job_group_i               AS job_group,
                         p_job_name_i                AS job_name,
                         v_name                      AS pkg_name,
                         v_subproc                   AS proc_name,
                         to_number (userenv ('sid')) AS session_id
                    FROM dual) v
              ON (tl.job_id = v.job_id)
      WHEN NOT MATCHED --insert means new job is running
      THEN
         INSERT     (job_id,
                     job_group,
                     job_name,
                     pkg_name,
                     proc_name,
                     job_starttime,
                     job_endtime,
                     status,
                     session_id)
             VALUES (v.job_id,
                     v.job_group,
                     v.job_name,
                     v.pkg_name, --note, this is only the package name, does not include the main proc
                     v.proc_name,
                     sysdate,
                     NULL,
                     'RUNNING',
                     v.session_id)
      WHEN MATCHED --update means job already started, and has either failed or finished normally
      THEN
         UPDATE SET tl.job_endtime = sysdate, tl.status = v_status;

      COMMIT;
   END log_timing;
END log_pkg;
/

SHOW ERRORS;


CREATE OR REPLACE SYNONYM pdm_stg.log_pkg FOR pdm_log.log_pkg;


CREATE OR REPLACE PUBLIC SYNONYM log_pkg FOR pdm_log.log_pkg;


GRANT EXECUTE ON pdm_log.log_pkg TO pdm_rpt;

GRANT EXECUTE ON pdm_log.log_pkg TO pdm_stg;