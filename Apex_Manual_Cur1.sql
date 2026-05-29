DECLARE
    -- Remove the cursor declaration and use direct cursor in FOR loop
BEGIN
    -- Check the APEX row status
    IF :APEX$ROW_STATUS = 'C' THEN  -- Insert
        FOR r IN (
            SELECT sdh.inventory_item_id,
                   sdh.sales_order_id,
                   sdh.country,
                   sdl.garment_inseam,
                   sdl.garment_size,
                   SUM(sdl.garment_size_qty) garment_size_qty,
                   sdh.dcpo_name,
                   REGEXP_SUBSTR(msib.description, '[^:]+', 1, 3) colour,
                   'N/A' child_style_no,
                   ooha.cust_po_number || '/' || oola.line_number bpo_line_number,
                   oola.attribute8 product_classification,
                   ooha.attribute3 classification,
                   ooha.attribute7 reference_tba,
                   sdh.ex_factory_date
              FROM pwc_ont_wvn_sizewise_details_l sdl,
                   pwc_ont_wvn_sizewise_details_h sdh,
                   apps.mtl_system_items@adf msib,
                   apps.oe_order_headers_all@adf ooha,
                   apps.oe_order_lines_all@adf oola,
                   pwc_ont_wvn_master_bom_bpo_l mbbla
             WHERE sdh.header_id = sdl.header_id
               AND ooha.header_id = oola.header_id
               AND oola.inventory_item_id = sdh.inventory_item_id
               AND oola.ordered_quantity <> 0
               AND NVL(oola.attribute2, 'No') = 'No'
               AND NVL(oola.attribute6, 'Active') = 'Active'
               AND oola.line_id = sales_order_line_id
               AND ooha.header_id = mbbla.sale_order_id
               AND msib.organization_id = :P7_INVOICING_UNIT_ID
               AND mbbla.sale_order_id = sdh.sales_order_id
               AND msib.inventory_item_id = sdh.inventory_item_id
               AND NVL(sdl.garment_size_qty, 0) > 0
               AND :P7_TRACKING_MODE = 'Master Style'
               AND mbbla.header_id = :P7_HEADER_ID
               AND oola.attribute8 = NVL(:PRODUCT_CLASSIFICATION, oola.attribute8)
             GROUP BY sdh.inventory_item_id,
                      sdh.sales_order_id,
                      sdh.country,
                      sdl.garment_inseam,
                      sdl.garment_size,
                      sdh.dcpo_name,
                      REGEXP_SUBSTR(msib.description,'[^:]+', 1, 3),
                      ooha.cust_po_number,
                      oola.line_number,
                      oola.attribute8,
                      ooha.attribute3,
                      ooha.attribute7,
                      sdh.ex_factory_date

             UNION ALL

             SELECT sdh.inventory_item_id,
                    sdh.sales_order_id,
                    sdh.country,
                    sdl.garment_inseam,
                    sdl.garment_size,
                    SUM(sdl.garment_size_qty),
                    sdh.dcpo_name,
                    REGEXP_SUBSTR(msib.description, '[^:]+', 1, 3),
                    NVL(oola.attribute4, 'N/A'),
                    ooha.cust_po_number || '/' || oola.line_number,
                    oola.attribute8,
                    ooha.attribute3,
                    ooha.attribute7,
                    sdh.ex_factory_date
               FROM pwc_ont_wvn_sizewise_details_l sdl,
                    pwc_ont_wvn_sizewise_details_h sdh,
                    apps.mtl_system_items@adf msib,
                    apps.oe_order_headers_all@adf ooha,
                    apps.oe_order_lines_all@adf oola,
                    pwc_ont_wvn_master_bom_bpo_l mbbla
              WHERE sdh.header_id = sdl.header_id
                AND ooha.header_id = oola.header_id
                AND oola.inventory_item_id = sdh.inventory_item_id
                AND oola.ordered_quantity <> 0
                AND NVL(oola.attribute2, 'No') = 'No'
                AND NVL(oola.attribute6, 'Active') = 'Active'
                AND oola.line_id = sales_order_line_id
                AND ooha.header_id = mbbla.sale_order_id
                AND msib.organization_id = :P7_INVOICING_UNIT_ID
                AND mbbla.sale_order_id = sdh.sales_order_id
                AND msib.inventory_item_id = sdh.inventory_item_id
                AND NVL(sdl.garment_size_qty, 0) > 0
                AND :P7_TRACKING_MODE = 'Child Style'
                AND mbbla.header_id = :P7_HEADER_ID
                AND oola.attribute4 = :P7_STYLE_NO
                AND oola.attribute8 = NVL(:PRODUCT_CLASSIFICATION, oola.attribute8)
             GROUP BY sdh.inventory_item_id,
                      sdh.sales_order_id,
                      sdh.country,
                      sdl.garment_inseam,
                      sdl.garment_size,
                      sdh.dcpo_name,
                      REGEXP_SUBSTR(msib.description,'[^:]+', 1, 3),
                      oola.attribute4,
                      ooha.cust_po_number,
                      oola.line_number,
                      oola.attribute8,
                      ooha.attribute3,
                      ooha.attribute7,
                      sdh.ex_factory_date
        ) LOOP
            INSERT INTO PWC_ONT_WVN_MASTER_BOM_GENRC_D
            (
                LINE_ID,
                INVENTORY_ITEM_ID,           
                SALE_ORDER_ID,
                BPO_LINE_NO, 
                CHILD_STYLE_NO,
                COUNTRY,
                DCPO_NAME,
                COLOUR,
                INSEAM_VAL,
                SIZE_VAL,
                SIZE_QUANTITY,
                CREATED_BY, 
                CREATION_DATE, 
                LAST_UPDATED_BY,
                LAST_UPDATE_DATE,
                PRODUCT_CLASSIFICATION, 
                SIZE_ASSIGNMENT
            )
            VALUES
            (
                :LINE_ID,
                r.inventory_item_id,
                r.sales_order_id, 
                r.bpo_line_number, 
                r.child_style_no,
                r.country,
                r.dcpo_name,
                r.colour,
                r.garment_inseam,
                r.garment_size,
                r.garment_size_qty,
                723155,
                SYSDATE,
                723155,
                SYSDATE,
                r.product_classification,
                'N'
            );
        END LOOP;

    ELSIF :APEX$ROW_STATUS = 'U' THEN  -- Update
        UPDATE PWC_ONT_WVN_MASTER_BOM_GENRC_D
        SET
            SIZE_ASSIGNMENT    = :SIZE_ASSIGNMENT,
            LAST_UPDATED_BY    = 723155,
            LAST_UPDATE_DATE   = SYSDATE     
        WHERE DETAIL_ID = :DETAIL_ID;

    ELSIF :APEX$ROW_STATUS = 'D' THEN  -- Delete
        DELETE FROM PWC_ONT_WVN_MASTER_BOM_GENRC_D
        WHERE DETAIL_ID = :DETAIL_ID;

    END IF;

    -- 		Success message
    -- 		APEX_APPLICATION.G_PRINT_SUCCESS_MESSAGE :=
    --  	'INVOICING_UNIT_ID: ' || :P7_INVOICING_UNIT_ID || '<br>' ||
    --   	'TRACKING_MODE: ' || :P7_TRACKING_MODE || '<br>' ||
    --   	'STYLE_NO: ' || :P7_STYLE_NO || '<br>' ||
    --   	'TRACKING_NO : ' || :P7_TRACKING_NO;
END;