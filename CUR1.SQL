DECLARE
BEGIN
   IF :APEX$ROW_STATUS = 'C' THEN

      FOR r IN (
         SELECT DISTINCT        
             ooha.order_number,
             oola.line_id,
             oola.shipped_quantity,
             oola.schedule_ship_date,
             ooha.ship_to_org_id AS country_change,

             ooha.cust_po_number || '/' || oola.line_number stn,        
             oola.ordered_item item_code,        
             msib.description item_description,        
             msib.inventory_item_id item_id,        
             oola.ordered_quantity quantity,     

             apps.pwc_poc_extra_quantity_func@adf(
                 ooha.attribute4, oola.ordered_quantity
             ) extra_qty,     

             ( SELECT NVL(SUM(TOTAL_CUT_QTY), 0)      
                 FROM PWC_MFG_CUTLYRCNTRL_H CH, 
                      PWC_MFG_CUTLYRCNTRL_L CL   
                WHERE CH.HEADER_ID = CL.HEADER_ID   
                  AND CH.TRACKING_NO = :p69_TRACKING_NO  
                  AND CH.ORG_ID = :p69_ORG_ID   
                  AND CL.BPO_NO = ooha.cust_po_number   
                  AND CL.COLOR = :p69_COLOR 
             ) current_plan_qty

         FROM apps.oe_order_headers_all@adf ooha        
         JOIN apps.oe_order_lines_all@adf oola 
              ON ooha.header_id = oola.header_id        
         JOIN apps.mtl_system_items_b@adf msib 
              ON msib.inventory_item_id = oola.ordered_item_id        

         WHERE msib.organization_id = pwc_organization_name('Inventory Master Org')        
           AND ooha.attribute4 = :P69_TRACKING_NO    
           AND REGEXP_SUBSTR(msib.description,'[^:]+',1,3) = :P69_ORG_ID       
           AND REGEXP_SUBSTR(msib.description,'[^:]+',1,2) = :P69_COLOR        
      )
      LOOP

         INSERT INTO PWC_GWP_MFG_GE_OBSLINE (
            GWP_GE_ID,
            GWP_GE_WASLINE_ID,
            GWP_GE_OBID,
            SALESORDER,
            SO_LINE,
            GWP_UNIT_ID,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            CREATION_DATE,
            CREATED_BY,
            OBS_NO,
            QUANTITY,
            POST_STATUS,
            JOB_STATUS,
            WIP_ENTITY_ID,
            JOB_RELEASED_DATE,
            WASH_NAME,
            WASHING_UNIT_NAME,
            WASHING_START_DATE,
            STITCHING_UNIT,
            STITCHING_START_DATE,
            VIEW_SHIPMENT_DETAIL,
            TEM_CODE,
            SHIPMENT_QTY,
            SHIPMENT_DATE,
            COUNTRY_CHANGE,
            INVENTORY_ITEM_ID,
            RECIPE_NO,
            NUMBER_BATCHES,
            PER_BATCH_QUANTITY,
            COLOR,
            WASH,
            WORKABLE_QUANTITY,
            STITCHING_FINISH_DATE,
            PRODUCTION_PER_DAY,
            WASH_SENDING_STARTDATE,
            WASH_SENDING_FINISHDATE,
            NUMBER_STITCHINGLINES,
            WASHING_FINISH_DATE,
            FEBRIC_TYPE,
            PER_BATCH_WEIGHT,
            SHADE_BAND_SEND_DATE,
            SHADE_BAND_SUB_DATE,
            SHADE_BAND_APPRO_DATE,
            ITEM_ID,
            JOB_NAME,
            JOB_QTY,
            JOB_ID,
            CURRENT_PLAN_QTY,
            JOB_CREATED,
            OB_POSTED,
            COMPLETION_POSTED,
            ERROR_MESSAGE,
            BALANCE_QTY,
            WASHING_END_DATE,
            REMARKS,
            EXTRA_QUANTITY
         )
         VALUES (
            :P69_GWP_GE_ID,
            :GWP_GE_WASLINE_ID,
            :GWP_GE_OBID,

            r.order_number,
            r.line_id,
            :GWP_UNIT_ID,

            SYSDATE,
            723155,
            SYSDATE,
            723155,

            r.stn,
            r.shipped_quantity,
            :POST_STATUS,
            :JOB_STATUS,

            :WIP_ENTITY_ID,
            :JOB_RELEASED_DATE,
            :WASH_NAME,
            :WASHING_UNIT_NAME,
            :WASHING_START_DATE,
            :STITCHING_UNIT,
            :STITCHING_START_DATE,
            :VIEW_SHIPMENT_DETAIL,
            :TEM_CODE,

            r.shipped_quantity,
            r.schedule_ship_date,
            r.country_change,
            r.item_id,

            :RECIPE_NO,
            :NUMBER_BATCHES,
            :PER_BATCH_QUANTITY,
            :COLOR,
            :WASH,
            :WORKABLE_QUANTITY,
            :STITCHING_FINISH_DATE,
            :PRODUCTION_PER_DAY,
            :WASH_SENDING_STARTDATE,
            :WASH_SENDING_FINISHDATE,
            :NUMBER_STITCHINGLINES,
            :WASHING_FINISH_DATE,
            :FEBRIC_TYPE,
            :PER_BATCH_WEIGHT,
            :SHADE_BAND_SEND_DATE,
            :SHADE_BAND_SUB_DATE,
            :SHADE_BAND_APPRO_DATE,

            r.item_id,
            :JOB_NAME,
            :JOB_QTY,
            :JOB_ID,

            r.current_plan_qty,
            :JOB_CREATED,
            :OB_POSTED,
            :COMPLETION_POSTED,
            :ERROR_MESSAGE,
            :BALANCE_QTY,
            :WASHING_END_DATE,
            :REMARKS,
            r.extra_qty
         );

      END LOOP;

   ELSIF :APEX$ROW_STATUS = 'U' THEN

      UPDATE PWC_GWP_MFG_GE_OBSLINE
         SET SALESORDER        = :SALESORDER,
             SO_LINE           = :SO_LINE,
             OBS_NO            = :OBS_NO,
             QUANTITY          = :QUANTITY,
             SHIPMENT_QTY      = :SHIPMENT_QTY,
             SHIPMENT_DATE     = :SHIPMENT_DATE,
             COUNTRY_CHANGE    = :COUNTRY_CHANGE,
             INVENTORY_ITEM_ID = :INVENTORY_ITEM_ID,
             CURRENT_PLAN_QTY  = :CURRENT_PLAN_QTY,
             EXTRA_QUANTITY    = :EXTRA_QUANTITY,
             LAST_UPDATED_BY   = 723155,
             LAST_UPDATE_DATE  = SYSDATE
       WHERE GWP_GE_WASLINE_ID = :GWP_GE_WASLINE_ID;

   ELSIF :APEX$ROW_STATUS = 'D' THEN

      DELETE FROM PWC_GWP_MFG_GE_OBSLINE
       WHERE GWP_GE_WASLINE_ID = :GWP_GE_WASLINE_ID;

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;