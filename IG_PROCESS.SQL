BEGIN
  CASE :APEX$ROW_STATUS
    /* ========= INSERT ========= */
    WHEN 'C' THEN
      INSERT INTO PWC_ONT_WVN_MASTER_BOM_ITEMS_L
      (HEADER_ID,ITEM_TYPE)
      VALUES
      (:HEADER_ID, :ITEM_TYPE)
       
      RETURNING LINE_ID INTO :LINE_ID;

    /* ========= UPDATE ========= */
    WHEN 'U' THEN
      UPDATE PWC_ONT_WVN_MASTER_BOM_ITEMS_L

      SET ITEM_TYPE                     = :ITEM_TYPE,
          PURCHASE_TYPE                 = :PURCHASE_TYPE
          
      WHERE LINE_ID                     = :LINE_ID;

    /* ========= DELETE ========= */
    WHEN 'D' THEN
      DELETE FROM PWC_ONT_WVN_MASTER_BOM_ITEMS_L
       WHERE LINE_ID      = :LINE_ID;

  END CASE;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(
      -20010,
      'Manual Row Process Error: ' || SQLERRM );
END;
