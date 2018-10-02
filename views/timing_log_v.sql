CREATE OR REPLACE VIEW pdm_log.timing_log_v
AS
   SELECT job_id,
          job_group,
          job_name,
          pkg_name,
          proc_name,
          job_starttime,
          job_endtime,
          round ( (job_endtime - job_starttime) * 24, 2)           AS elapsed_hours,
          round ( (job_endtime - job_starttime) * 24 * 60, 2)      AS elapsed_min,
          round ( (job_endtime - job_starttime) * 24 * 60 * 60, 2) AS elapsed_sec,
          status,
          session_id
     FROM pdm_log.timing_log tl;

GRANT SELECT ON pdm_log.timing_log_v TO pdm_stg, pdm_rpt;