SET DEFINE OFF

CREATE OR REPLACE PACKAGE BODY pdm_log.demo_pkg
IS
    PROCEDURE do_stuff
    IS
    BEGIN
        null; -- your task here
    END do_stuff;

    PROCEDURE main (p_job_group_i IN VARCHAR2, p_job_name_i IN VARCHAR2, p_fail_i IN CHAR DEFAULT 'N')
    IS
    BEGIN
        log_pkg.log_timing (p_job_group_i, p_job_name_i);
        --*** CODE BEGIN ***

        IF p_fail_i = 'Y'
        THEN
            mail_pkg.send (p_job_name_i || ' failed!',
                           'Your message body here',
                           p_to_i   => 'someaddy@somedomain.com');
            RAISE no_data_found;
        END IF;

        do_stuff ();

        mail_pkg.send (p_job_name_i || ' success!',
                       'Your message body here',
                       p_to_i   => 'someaddy@somedomain.com');
        --*** CODE END ***
        log_pkg.log_timing (p_job_group_i, p_job_name_i);
    EXCEPTION
        WHEN OTHERS
        THEN
            log_pkg.log ('When Others');
            log_pkg.log_timing (p_job_group_i, p_job_name_i);
            DBMS_OUTPUT.put_line (
                chr (10) || SQLERRM || '. ERROR TRACE: ' || DBMS_UTILITY.format_error_backtrace || chr (10));
            RAISE; -- pass exception back to calling client
    END main;
END demo_pkg;
/