USE dw_bronze;

SELECT COUNT(*) AS customer_count
FROM crm_cust_info;

SELECT COUNT(*) AS product_count
FROM crm_prd_info;

SELECT COUNT(*) AS sales_count
FROM crm_sales_details;

SELECT COUNT(*) AS erp_customer_count
FROM erp_cust_az12;

SELECT COUNT(*) AS erp_location_count
FROM erp_loc_a101;

SELECT COUNT(*) AS erp_category_count
FROM erp_px_cat_g1v2;
