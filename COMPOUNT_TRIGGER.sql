create or replace TRIGGER "TRIGGER_MASTER_BOM_GENRC_D_SIZE_QTY" 
FOR INSERT OR UPDATE OR DELETE
ON PWC_ONT_WVN_MASTER_BOM_GENRC_D
COMPOUND TRIGGER

    -- collection to store affected LINE_IDs
    TYPE t_line_ids IS TABLE OF NUMBER;
    g_line_ids t_line_ids := t_line_ids();

    AFTER EACH ROW IS
    BEGIN
        g_line_ids.EXTEND;
        g_line_ids(g_line_ids.LAST) :=
            NVL(:NEW.LINE_ID, :OLD.LINE_ID);
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        FOR i IN 1 .. g_line_ids.COUNT LOOP
            UPDATE PWC_ONT_WVN_MASTER_BOM_ITEMS_L L
               SET L.GARMENT_QTY =
                   (
                       SELECT NVL(SUM(D.SIZE_QUANTITY), 0)
                         FROM PWC_ONT_WVN_MASTER_BOM_GENRC_D D
                        WHERE 1=1
                        AND SIZE_ASSIGNMENT='Y'
                        AND D.LINE_ID = g_line_ids(i)
                    )
             WHERE L.LINE_ID = g_line_ids(i);
        END LOOP;
    END AFTER STATEMENT;

END;
/

