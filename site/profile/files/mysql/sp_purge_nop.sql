delimiter $$
DROP PROCEDURE IF EXISTS sp_purge_ttt$$
CREATE PROCEDURE sp_purge_ttt()
BEGIN
DECLARE v_now DATETIME;
DECLARE v_purgedate DATE;
DECLARE v_batch, v_out, v_cnt_ttt_messages, 
        v_cnt_ttt_order_events, v_cnt_ttt_order_states, 
        v_cnt_ttt_quote_events, v_cnt_ttt_quote_states INT;
DECLARE v_maxid_ttt_messages, 
        v_maxid_ttt_order_events, v_maxid_ttt_order_states, 
        v_maxid_ttt_quote_events, v_maxid_ttt_quote_states BIGINT;

SET v_now = NOW();
# try to release lock, if procedure is executed by same session several times and any error appeared
SELECT RELEASE_LOCK('ttt_purge') INTO v_out;
-- check, if procedure is already running using user-level locks
IF (SELECT IS_FREE_LOCK('ttt_purge')) = 1 THEN 
  #In case of error lock is released automatically after connection is closed.
  IF (SELECT GET_LOCK('ttt_purge',10)) = 1 THEN 
	SET sql_log_bin=0;

    #Sun-1,Mon-2.
    CASE WHEN DAYOFWEEK(v_now) IN (1,2,3,4) THEN SET v_purgedate=DATE(v_now-interval 4 day);
       WHEN DAYOFWEEK(v_now) IN (5,6) THEN SET v_purgedate=DATE(v_now-interval 2 day);
       WHEN DAYOFWEEK(v_now) IN (7) THEN SET v_purgedate=DATE(v_now-interval 3 day);
       ELSE SET v_purgedate=DATE(v_now);
    END CASE; 

  #get maxid till which rows will be deleted and amount of rows to delete
  SELECT MAX(id), COUNT(*) 
    INTO v_maxid_ttt_messages, v_cnt_ttt_messages
    FROM ttt_messages
   WHERE arrival_time < v_purgedate;

  SELECT MAX(id), COUNT(*)
    INTO v_maxid_ttt_order_events, v_cnt_ttt_order_events
    FROM ttt_order_events
   WHERE timestamp < (unix_timestamp(v_purgedate)*1000);

  SELECT MAX(id), COUNT(*)
    INTO v_maxid_ttt_order_states, v_cnt_ttt_order_states
    FROM ttt_order_states
  WHERE timestamp < (unix_timestamp(v_purgedate)*1000);

  SELECT MAX(id), COUNT(*)
    INTO v_maxid_ttt_quote_events, v_cnt_ttt_quote_events
    FROM ttt_quote_events                                   
   WHERE ttt_timestamp_nanos < (unix_timestamp(v_purgedate)*1000000000);

  SELECT MAX(id), COUNT(*)
    INTO v_maxid_ttt_quote_states, v_cnt_ttt_quote_states
    FROM ttt_quote_states
   WHERE modified_timestamp_millis < (unix_timestamp(v_purgedate)*1000);


	# get number of delete batches by 1000000 rows
	SET v_batch = CEILING(GREATEST(IFNULL(v_cnt_ttt_messages,0),
                                 IFNULL(v_cnt_ttt_quote_states,0),
                                 IFNULL(v_cnt_ttt_quote_events,0),
                                 IFNULL(v_cnt_ttt_order_states,0),
                                 IFNULL(v_cnt_ttt_order_events,0))
                         /1000000);

	# loop for delete batches
	WHILE v_batch > 0 DO
        # Stop script, if it is working hours
        IF TIME(NOW()) > '08:00:00' AND TIME(NOW()) < '19:00:00' AND dayofweek(NOW()) IN (2,3,4,5,6) THEN
          SET v_batch=0;
          SELECT RELEASE_LOCK('ttt_purge') INTO v_out;
          SET sql_log_bin=1;
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'It is working hours. TTT purging was stopped!';
        END IF;
        # Purge old records.	    
        DELETE FROM ttt_order_states WHERE id <= v_maxid_ttt_order_states LIMIT 1000000;
        DELETE FROM ttt_order_events WHERE id <= v_maxid_ttt_order_events LIMIT 1000000;
        DELETE FROM ttt_quote_states WHERE id <= v_maxid_ttt_quote_states LIMIT 1000000;
        DELETE FROM ttt_quote_events WHERE id <= v_maxid_ttt_quote_events LIMIT 1000000;
        DELETE FROM ttt_messages WHERE id <= v_maxid_ttt_messages LIMIT 1000000;
       
	    SET v_batch=v_batch-1;
	END WHILE;

  SELECT CONCAT('Number of deleted rows in ttt_messages: ',v_cnt_ttt_messages);
  SELECT CONCAT('Number of deleted rows in ttt_order_states: ',v_cnt_ttt_order_states);
  SELECT CONCAT('Number of deleted rows in ttt_order_events: ',v_cnt_ttt_order_events);
  SELECT CONCAT('Number of deleted rows in ttt_quote_states: ',v_cnt_ttt_quote_states);
  SELECT CONCAT('Number of deleted rows in ttt_quote_events: ',v_cnt_ttt_quote_events);
	# free lock
	SELECT RELEASE_LOCK('ttt_purge') INTO v_out;
  END IF;

ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Can not get user lock. Is procedure already running?';
END IF;
END$$

delimiter ;
