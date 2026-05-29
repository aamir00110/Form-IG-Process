DECLARE
  l_count NUMBER := 0;
BEGIN

     FOR r IN (
     SELECT DISTINCT
            msib.concatenated_segments ordered_item,
            msib.inventory_item_id,
            CASE msib.segment3
                WHEN '11' THEN 'Local'
                WHEN '21' THEN 'Imported'
                ELSE 'N/A'
            END status,
            msib.description,
            msib.description acc_desc,
            msib.primary_unit_of_measure,
            v.description value_description,
            msib.attribute5 supplier_legacy_code,
            msib.segment1,
            tcl.finish_garment_colour color,
            tcl.consumption,
            (SELECT papx.full_name
             FROM apps.per_people_x@adf papx
             WHERE papx.person_id = msib.buyer_id) buyer_name,
            msib.buyer_id,
            msib.attribute3 supplier_name,
            REGEXP_REPLACE(msib.attribute11, '[^0-9]', '') thread_length,
            tcl.department,
            tcl.thread_brand,
            tcl.thread_tkt,
            tcl.thread_tex,
            tcl.thread_count,
            tcl.thread_shade,
            tcl.thread_color,
            ROUND(tcl.consumption / msib.attribute27, 5) cone_consumption,
            APPS.PWC_ITEM_STATUS_DESCRIPTION@adf(msib.segment3) item_status,
            NULL hanger_no,
            NULL article_no,
            NULL order_line_id,
            NULL Job_M2,
            NULL RATE,
            NULL Last_supplier_name,
            (SELECT NVL(MAX(LR.LAST_PUR_RATE), 0)
             FROM apps.MTML_PO_ITEM_LAST_RATE@adf LR
             WHERE LR.ORGANIZATION_ID = msib.organization_id
               AND LR.INVENTORY_ITEM_ID = msib.inventory_item_id) LAST_PUR_RATE
        FROM apps.mtl_system_items_kfv@adf msib
        JOIN pwc_flex_values_v v
          ON v.flex_value_set_name = 'MTML_K_INV_SYSTEM_ITEM_PREFIX'
         AND v.flex_value = msib.segment1
        JOIN pwc_ont_wvn_thrd_consumption_l tcl
          ON tcl.inventory_item_id = msib.inventory_item_id
        JOIN pwc_ont_wvn_thrd_consumption_h tch
          ON tch.header_id = tcl.header_id
         AND tch.tracking_no = :P7_Tracking_No
        WHERE msib.organization_id = :P7_INVOICING_UNIT_ID
          AND msib.segment3 IN ('11','21')
          AND msib.enabled_flag = 'Y'
          AND msib.inventory_item_status_code = 'Active'
          AND NVL(tcl.status_flag,'N') = 'Y'
          AND msib.segment1 = '451'
          AND :P7_ItemType = 'Thread'
          AND (:p_PrefixSecurity IS NOT NULL OR :p_PrefixSecurity IS NULL)
      
  ) 
  LOOP

    INSERT INTO PWC_ONT_WVN_MASTER_BOM_ITEMS_L
    (
      LINE_ID,
      HEADER_ID,
      ITEM_TYPE,
      PURCHASE_TYPE,
      ITEM_PREFIX,
      INVENTORY_ITEM_ID,
      SUPPLIER_NOMINATION,
      ITEM_SUPP_NAME,
      ITEM_REMARKS,
      UOM_CONV_RATE,
      ITEM_CONSUMPTION,
      ITEM_WASTAGE,
      ITEM_BOM_REQ_QTY,
      ITEM_BOOKING_PRCNT,
      ITEM_ADDITIONAL_QTY,
      ITEM_ACTUAL_PR_QTY,
      ITEM_BOOKED_PRCNT,
      ITEM_TOTAL_BOOKED_QTY,
      ITEM_PENDING_BOOKING_PRCNT,
      ITEM_PENDING_BOOKING_QTY,
      ITEM_PRICE_PER_UNIT,
      ITEM_TOTAL_VALUE,
      CREATED_BY,
      CREATION_DATE,
      LAST_UPDATED_BY,
      LAST_UPDATE_DATE,
      CHILD_STYLE_NO,
      PRODUCTION_AREA,
      ITEM_ORGANIZATION_ID,
      PRODUCT_CLASSIFICATION,
      COSTING_UOM,
      PROCUREMENT_UOM,
      POC_ITEM_PRICE_PER_UNIT,
      POC_ITEM_CONSUMPTION,
      POC_UOM_CONV_RATE,
      POC_COST_PER_PIECE,
      CONE_CONSUMPTION,
      ITEM_STATUS,
      M2_ORDER_LINE_ID,
      M2_JOB_NAME,
      M2_ITEM_RATE,
      TBC_TRACKING_NO
    )
    VALUES
    (
      null,
      :P7_HEADER_ID,
      :P7_ITEMTYPE,
      r.STATUS,
      r.SEGMENT1,
      r.INVENTORY_ITEM_ID,
      r.SUPPLIER_LEGACY_CODE,
      r.SUPPLIER_NAME,
      r.DESCRIPTION,
      NVL(r.THREAD_LENGTH,0),
      NVL(r.CONSUMPTION,0),
      0,
      NVL(r.CONSUMPTION,0),
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      NVL(r.LAST_PUR_RATE,0),
      NVL(r.LAST_PUR_RATE,0)*NVL(r.CONSUMPTION,0),
      0,
      SYSDATE,
      0,
      SYSDATE,
      NULL,
      r.DEPARTMENT,
      :P7_INVOICING_UNIT_ID,
      :PRODUCT_CLASSIFICATION,
      r.PRIMARY_UNIT_OF_MEASURE,
      r.PRIMARY_UNIT_OF_MEASURE,
      NVL(r.LAST_PUR_RATE,0),
      NVL(r.CONSUMPTION,0),
      NVL(r.THREAD_LENGTH,0),
      NVL(r.CONE_CONSUMPTION,0),
      NVL(r.CONE_CONSUMPTION,0),
      r.ITEM_STATUS,
      r.ORDER_LINE_ID,
      r.JOB_M2,
      NVL(r.RATE,0),
      :P7_TRACKING_NO
    );

    l_count := l_count + 1;
  END LOOP;

COMMIT;
  :P7_INSERT_COUNT := l_count;

EXCEPTION
  WHEN NO_DATA_FOUND THEN NULL;

END;