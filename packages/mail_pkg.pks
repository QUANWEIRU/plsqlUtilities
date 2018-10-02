CREATE OR REPLACE PACKAGE pdm_log.mail_pkg
/*
Description: Utility procedures for the Oracle Mailer. Repurposes former IKB code provided by Jim Marshall.
==========================================================================================================#
DATE---------> MOD/ISSUES---> LOGID --->ANALYST----> DESCRIPTION
==========================================================================================================#
04/17/2017 -->           ---> N/A   --->WREICHL ---> Initial creation.
==========================================================================================================#
*/
IS
   PROCEDURE send (p_subject_i   IN VARCHAR2,
                   p_message_i   IN VARCHAR2,
                   p_from_i      IN VARCHAR2 DEFAULT NULL,
                   p_to_i        IN VARCHAR2 DEFAULT NULL,
                   p_cc_i        IN VARCHAR2 DEFAULT NULL);
END mail_pkg;
/

grant execute on pdm_log.mail_pkg to pdm_stg, pdm_rpt, mdm_stg, ebir_stg;

SHOW ERRORS;