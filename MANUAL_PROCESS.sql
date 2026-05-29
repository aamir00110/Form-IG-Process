DECLARE
---------------VARIABLE DECLARE SECTION------------    
BEGIN
    -- Check the APEX row status
    IF :APEX$ROW_STATUS = 'C' THEN  -- Insert
        FOR r IN

	(---------------SELECT STATEMENT----------------) 

	LOOP

	 /* ================= INSERT ================= */

ELSIF	INSERT INTO TABLE_NAME
				(COLUMN1,COLUMN2)
	VALUES			(R.COLUMN1,R.COLUMN2);
	WHERE PRIMARYKEY =:PRIMARYKEY
	END LOOP;

	  /* ================= UPDATE ================= */ 
ELSIF    IF :APEX$ROW_STATUS = 'D' THEN  -- DELETE
	set column1 =:item1,
	column2     =:item2
	WHERE PRIMARYKEY =:PRIMARYKEY
END IF;
END IF;
END;