DECLARE
    v_duplicat_count NUMBER := 0;
    v_master_bom_Item_count NUMBER := 0;
    v_line_id NUMBER;
    v_thread_brand VARCHAR2(255);
    v_thread_shade VARCHAR2(255);
    v_thread_color VARCHAR2(255);
    v_thread_tkt VARCHAR2(255);
    v_thread_tex VARCHAR2(255);
    v_thread_count VARCHAR2(255);
    v_length VARCHAR2(50);
    v_meters VARCHAR2(50);
BEGIN
    CASE :APEX$ROW_STATUS
        WHEN 'C' THEN  -- Create
            -- Get next LINE_ID (handle empty table)
            SELECT NVL(MAX(LINE_ID),0) + 1
            INTO v_line_id
            FROM PWC_ONT_WVN_THRD_CONSUMPTION_L;

            -- Get Item Details from INVENTORY_ITEM_CODE
            BEGIN
               --Select statement here---
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    raise_application_error(-20001, 'Item not found for code: ' || /*:Dubilicate_column_show*/);
            END;

            -- Check duplicate in grid
            SELECT COUNT(*)
            INTO v_duplicat_count
            FROM PWC_ONT_WVN_THRD_CONSUMPTION_L
            WHERE HEADER_ID = :P26_HEADER_ID
              AND INVENTORY_ITEM_ID = :INVENTORY_ITEM_ID;

            IF v_duplicat_count > 0 THEN
                raise_application_error(-20001, 'This item is already tagged here: ' || /*:Dubilicate_column_show*/);
            END IF;

            -- Insert only if no duplicate
            INSERT INTO table(
                column1,column2
            ) VALUES (
                :item1,:item2
            );

        WHEN 'U' THEN  -- Update
            UPDATE table
            SET column1 = :column1,
                column2 = :column2,
            WHERE ROWID = :ROWID;

        WHEN 'D' THEN  -- Delete
            -- Check if item exists in Master BOM
            SELECT COUNT(*)
            INTO v_master_bom_Item_count
            FROM PWC_ONT_WVN_MASTER_BOM_H h
            JOIN PWC_ONT_WVN_MASTER_BOM_ITEMS_L l
              ON h.HEADER_ID = l.HEADER_ID
            WHERE h.TRACKING_NO = (SELECT TRACKING_NO FROM  PWC_ONT_WVN_THRD_CONSUMPTION_H where HEADER_ID = :HEADER_ID)
              AND l.INVENTORY_ITEM_ID = :INVENTORY_ITEM_ID;

            IF v_master_bom_Item_count > 0 THEN
                raise_application_error(-20001, 'Unable to delete this Line because this Item is tagged on Master BoM');
            END IF;

            DELETE FROM PWC_ONT_WVN_THRD_CONSUMPTION_L
            WHERE ROWID = :ROWID;

    END CASE;
END;
