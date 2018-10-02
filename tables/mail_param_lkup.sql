--DROP TABLE pdm_log.mail_param_lkup;

CREATE TABLE pdm_log.mail_param_lkup
(
   param_name    VARCHAR2 (10) PRIMARY KEY,
   param_value   VARCHAR2 (1000),
   create_dttm   DATE,
   create_user   VARCHAR2 (50),
   update_dttm   DATE,
   update_user   VARCHAR2 (50)
);

INSERT INTO mail_param_lkup (param_name,
                             param_value,
                             create_dttm,
                             create_user,
                             update_dttm,
                             update_user)
     VALUES ('FROM',
             'OracleMailerPDMD@dcsg.com',
             sysdate,
             user,
             sysdate,
             user);

INSERT INTO mail_param_lkup (param_name,
                             param_value,
                             create_dttm,
                             create_user,
                             update_dttm,
                             update_user)
     VALUES ('TO',
             'William.Reichl@dcsg.com',
             sysdate,
             user,
             sysdate,
             user);

INSERT INTO mail_param_lkup (param_name,
                             param_value,
                             create_dttm,
                             create_user,
                             update_dttm,
                             update_user)
     VALUES ('CC',
             NULL,
             sysdate,
             user,
             sysdate,
             user);
             
commit;             