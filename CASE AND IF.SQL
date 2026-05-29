------------IF STATEMENT---------------

BEGIN
  IF :APEX$ROW_STATUS = 'C' THEN
    INSERT INTO my_table (...) VALUES (...);
  ELSIF :APEX$ROW_STATUS = 'U' THEN
    UPDATE my_table SET ... WHERE LINE_ID = :LINE_ID;
  ELSIF :APEX$ROW_STATUS = 'D' THEN
    DELETE FROM my_table WHERE LINE_ID = :LINE_ID;
  END IF;
END;


-----------------------CURSOR WITH LOOP--------------

BEGIN
  FOR r IN (
    SELECT DISTINCT
      inventory_item_id,
      FROM your_source_table
    WHERE some_condition = :P7_TRACKING_NO
  ) LOOP

    -- Check row status from IG

    IF :APEX$ROW_STATUS = 'C' THEN
       -- Insert multiple records
       INSERT INTO your_target_table (
         HEADER_ID,
         INVENTORY_ITEM_ID,
       
       )
       VALUES (
         :P7_HEADER_ID,
         r.INVENTORY_ITEM_ID
         
       );

    ELSIF :APEX$ROW_STATUS = 'U' THEN
       -- Update multiple records
       UPDATE your_target_table
       SET ITEM_STATUS             = :ITEM_STATUS,
           ITEM_SUPP_NAME          = :ITEM_SUPP_NAME
       WHERE LINE_ID = :LINE_ID;

    ELSIF :APEX$ROW_STATUS = 'D' THEN
       -- Delete multiple records
       DELETE FROM your_target_table
       WHERE LINE_ID = :LINE_ID;
    END IF;

  END LOOP;

  COMMIT;
END;
