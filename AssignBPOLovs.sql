SELECT NULL line_id,
         bpo_info.header_id,
         bpo_info.bpo_number,
         bpo_info.sales_order_id,
         bpo_info.classification,
         bpo_info.fit,
         bpo_info.retailer_dept,
         bpo_info.item_description,
         NVL (SUM (bpo_info.ordered_qty), 0) ordered_qty,
         bpo_info.tracking_no,
         bpo_info.final_replace_bpo,
         bpo_info.ref_tba,
        CASE
             WHEN NVL (SUM (bpo_info.adjusted_quantity), 0) >= 0
             THEN NVL (SUM (bpo_info.adjusted_quantity), 0)
             ELSE 0
        END adjusted_quantity,
        NVL (SUM (Extra_Cut_Quantity), 0) Extra_Cut_Quantity
        FROM(  
                SELECT ooha.header_id,
                es.sales_order_id,
                ooha.cust_po_number bpo_number,
                ooha.attribute3 classification,
                wph.fit,
                wph.retailer_dept,
                wph.item_description,
                SUM (oola.ordered_quantity) ordered_qty,
                wph.tracking_no,
                ooha.attribute12 final_replace_bpo,
                ooha.attribute7 ref_tba,
                (SUM (oola.ordered_quantity)
                    - (NVL (
                          (SELECT SUM (oolai.ordered_quantity)
                             FROM apps.oe_order_headers_all@adf oohai,
                                  apps.oe_order_lines_all@adf oolai
                            WHERE     oohai.header_id = oolai.header_id
                                  AND oohai.flow_status_code <> 'CANCELLED'
                                  AND oohai.attribute7 = ooha.cust_po_number
                                  AND oohai.attribute4 = wph.tracking_no),
                          0)))     adjusted_quantity,
                   (SELECT NVL (SUM (es.SHIPMENT_QTY), 0)
                      FROM PWC_ONT_WVN_SIZEWISE_DETAILS_H es
                     WHERE es.sales_order_line_id = oola.line_id
                       AND es.SALES_ORDER_ID = ooha.header_id)
                      Extra_Cut_Quantity
              FROM apps.oe_order_headers_all@adf ooha,
                   apps.oe_order_lines_all@adf oola,
                   pwc_ont_wvn_precosting_h wph,
                   PWC_ONT_WVN_SIZEWISE_DETAILS_H es
               
             WHERE 1=1    
                   AND ooha.attribute4 = TO_CHAR (wph.tracking_no)
                   AND ooha.header_id = oola.header_id
                   AND es.sales_order_line_id = oola.line_id
                   AND es.sales_order_id     = ooha.header_id
                   AND ooha.flow_status_code <> 'CANCELLED'
                   AND oola.ordered_quantity <> 0
                   AND NVL (oola.attribute2, 'No') = 'No'
                   AND UPPER (NVL (oola.attribute6, 'Active')) = 'ACTIVE'
                   AND wph.tracking_no = NVL (:p7_Tracking_No, wph.tracking_no)
                 

/*                 AND NOT EXISTS
                              (SELECT 1
                                 FROM pwc_ont_wvn_master_bom_bpo_l bbl,
                                      pwc_ont_wvn_master_bom_h mbh
                                WHERE     mbh.header_id = bbl.header_id
                                      AND ooha.cust_po_number = bbl.bpo_number
                                      AND ooha.header_id = bbl.sale_order_id
                                      AND mbh.tracking_no = wph.tracking_no)
*/
          GROUP BY ooha.cust_po_number,
                   ooha.attribute3,
                   wph.fit,
                   wph.retailer_dept,
                   wph.tracking_no,
                   es.sales_order_id,
                   wph.item_description,
                   ooha.header_id,
                   ooha.attribute12,
                   ooha.attribute7,
                   oola.line_id) bpo_info
   WHERE bpo_info.adjusted_quantity > 0
GROUP BY bpo_info.header_id,
         bpo_info.bpo_number,
         bpo_info.classification,
         bpo_info.fit,
         bpo_info.sales_order_id,
         bpo_info.retailer_dept,
         bpo_info.item_description,
         bpo_info.tracking_no,
         bpo_info.final_replace_bpo,
         bpo_info.ref_tba