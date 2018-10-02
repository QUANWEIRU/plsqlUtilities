CREATE OR REPLACE PACKAGE BODY pdm_log.mail_pkg
/*
Description: Utility procedures for the Oracle Mailer. Repurposes former IKB code provided by Jim Marshall.
==========================================================================================================#
DATE---------> MOD/ISSUES---> LOGID --->ANALYST----> DESCRIPTION
==========================================================================================================#
04/17/2017 -->           ---> N/A   --->WREICHL ---> Initial creation.
06/27/2017 -->           ---> 1001  --->WREICHL ---> Added ability to send to multiple TO or CC addresses.
==========================================================================================================#
*/
IS
   /**
    * Assuming most mail will go to a standard distro or list. Grab these values from a lookup table,
    * and then the calling code will only need to send two parameters, for subject and message.
    * p_mailparam_type_i - { 'FROM','TO','CC' }
    * Will throw NO_DATA_FOUND exception if mailparam type not found in lookup table.
    */
   FUNCTION get_default (p_mailparam_type_i IN VARCHAR2)
      RETURN VARCHAR2
   IS
      v_param_value   pdm_log.mail_param_lkup.param_value%TYPE;
   BEGIN
      SELECT mpl.param_value
        INTO v_param_value
        FROM pdm_log.mail_param_lkup mpl
       WHERE mpl.param_name = p_mailparam_type_i;

      RETURN v_param_value;
   END get_default;

   PROCEDURE send (p_subject_i   IN VARCHAR2,
                   p_message_i   IN VARCHAR2,
                   p_from_i      IN VARCHAR2 DEFAULT NULL,
                   p_to_i        IN VARCHAR2 DEFAULT NULL,
                   p_cc_i        IN VARCHAR2 DEFAULT NULL)
   IS
      crlf   CONSTANT VARCHAR2 (2) := UTL_TCP.crlf;
      v_connection    UTL_SMTP.connection;
      v_host          VARCHAR2 (100);
      v_mailhost      VARCHAR2 (100);
      v_header        VARCHAR2 (1000);
      v_message       VARCHAR2 (32767);
      v_from          VARCHAR2 (100);
      v_to            VARCHAR2 (1000);
      v_cc            VARCHAR2 (1000);
   BEGIN
      SELECT host_name INTO v_host FROM v$instance;

      --Get defaults from PDM_LOG.MAIL_PARAM_LKUP for any not specified
      v_from := nvl (p_from_i, get_default ('FROM'));
      v_to := nvl (p_to_i, get_default ('TO'));
      v_cc := nvl (p_cc_i, get_default ('CC')); --this will still be NULL if no CC desired

      v_mailhost := v_host || '.dcsg.com';
      v_message := SUBSTR (p_message_i, 1, 32767);
      v_message := REPLACE (v_message, '\n', chr (10));
      v_connection := UTL_SMTP.open_connection (v_mailhost, 25);
      v_header :=
            'Date: '
         || to_char (systimestamp, 'dd Mon yy hh24:mi:ss tzhtzm')
         || crlf
         || 'From: '
         || v_from
         || ''
         || crlf
         || 'Subject: '
         || p_subject_i
         || crlf
         || 'To: '
         || v_to
         || crlf;

      IF v_cc IS NOT NULL
      THEN
         v_header := v_header || 'CC: ' || v_cc;
      END IF;

      --
      -- Handshake with the SMTP server
      --
      UTL_SMTP.helo (v_connection, v_mailhost);
      UTL_SMTP.mail (v_connection, v_from);

      --
      -- LOGID 1001
      -- Loop over multiple recipients, creating a RCPT for each.
      -- Can be separated by commas or semi-colons.
      --
      FOR x IN (WITH t AS (SELECT replace (v_to, ',', ';') AS to_list FROM dual)
                    SELECT level AS n,
                           regexp_substr (to_list,
                                          '[^;]+',
                                          1,
                                          level)
                              AS to_address
                      FROM t
                CONNECT BY regexp_substr (to_list,
                                          '[^;]+',
                                          1,
                                          level)
                              IS NOT NULL)
      LOOP
         UTL_SMTP.rcpt (v_connection, trim (x.to_address));
      END LOOP;

      IF v_cc IS NOT NULL
      THEN
         --LOGID 1001: Added loop over multiple addresses
         FOR x IN (WITH t AS (SELECT replace (v_cc, ',', ';') AS cc_list FROM dual)
                       SELECT level AS n,
                              regexp_substr (cc_list,
                                             '[^;]+',
                                             1,
                                             level)
                                 AS cc_address
                         FROM t
                   CONNECT BY regexp_substr (cc_list,
                                             '[^;]+',
                                             1,
                                             level)
                                 IS NOT NULL)
         LOOP
            UTL_SMTP.rcpt (v_connection, trim (x.cc_address));
         END LOOP;
      END IF;

      UTL_SMTP.open_data (v_connection);
      --
      -- Write the header
      --
      UTL_SMTP.write_data (v_connection, v_header);
      --
      -- The crlf is required to distinguish that what comes next is not simply part of the header..
      --
      UTL_SMTP.write_data (v_connection, crlf || v_message);
      UTL_SMTP.close_data (v_connection);
      UTL_SMTP.quit (v_connection);
   END send;
END mail_pkg;
/

GRANT EXECUTE ON pdm_log.mail_pkg TO pdm_stg; -- allow other users/schemas to reference
GRANT EXECUTE ON pdm_log.mail_pkg TO pdm_rpt; -- allow other users/schemas to reference

SHOW ERRORS;