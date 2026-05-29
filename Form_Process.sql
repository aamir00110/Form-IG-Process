DECLARE
   v_header_id   NUMBER;
   
   v_user_id     NUMBER;
BEGIN
   /* Generate new HEADER_ID & BOM_NUMBER */
   SELECT NVL(MAX(header_id), 0) + 1,
     INTO v_header_id
          
     FROM PWC_ONT_WVN_MASTER_BOM_H;

   /* Set Page Items */
   :P7_HEADER_ID  := v_header_id;
   
   /* Get APEX User ID */
   BEGIN
      SELECT user_id
        INTO v_user_id
        FROM APEX_230200.WWV_FLOW_USERS
       WHERE user_name = :APP_USER;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_user_id := NULL;
   END;

   :P7_CREATED_BY := v_user_id;

   /* Insert into Header Table */
   INSERT INTO PWC_ONT_WVN_MASTER_BOM_H
   (
      HEADER_ID,
      BOM_NUMBER,
      BOM_DATE,
      TRACKING_NO,
      RETAILER_DEPT,
      COPIED_FROM_BOM,
      INVOICING_UNIT_ID,
      CREATED_BY,
      CREATION_DATE,
      BUYER_ID,
      PS_CODE,
      TXN_MESSAGE
   )
   VALUES
   (
      v_header_id,
      v_bom_number,
      :P7_BOM_DATE,
      :P7_TRACKING_NO,
      :P7_RETAILER_DEPT,
      :P7_COPIED_FROM_BOM,
      :P7_INVOICING_UNIT_ID,
      v_user_id,
      SYSDATE,
      :P7_BUYER_ID,
      :P7_PS_CODE,
      'BOM CREATED'
   );

   apex_application.g_print_success_message := 'BOM created successfully. BOM No: ' || v_bom_number;

END;







