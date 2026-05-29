DECLARE
V_CONSUMPTION NUMBER;
BEGIN
IF :PCS_PER_CARTON IS NOT NULL 
AND :PCS_PER_CARTON !=0
THEN V_CONSUMPTION := ROUND(1 / PCS_PER_CARTON , 6);
ELSE
V_CONSUMPTION := NULL;
ELSIF;
 
 IF APEX$ROW_STATUS = 'C' THEN
	 INSERT INTO pwc_ont_wvn_cart_consumption_l
      (
         line_id,
         header_id,
         inventory_item_id,
         consumption,
         department,
         pcs_per_carton,
         created_by,
         creation_date
      )
      VALUES
      (
         NULL,                 
         :P35_HEADER_ID,
         :INVENTORY_ITEM_ID,
         v_consumption,
         :DEPARTMENT,
         :PCS_PER_CARTON,
         723155,
         SYSDATE
      );
	ELSIF	APEX$ROW_STATUS = 'U' THEN
	 UPDATE pwc_ont_wvn_cart_consumption_l
         SET inventory_item_id = :INVENTORY_ITEM_ID,
             consumption       = v_consumption,
             department        = :DEPARTMENT,
             pcs_per_carton    = :PCS_PER_CARTON,
             last_updated_by   = 723155,
             last_update_date  = SYSDATE
       WHERE line_id = :LINE_ID;
	   
	ELSIF APEX$ROW_STATUS ='D' THEN
		DELETE FROM pwc_ont_wvn_cart_consumption_l
       WHERE line_id = :LINE_ID;

		END IF;

EXCEPTION
			OTHERS THEN NULL;
END