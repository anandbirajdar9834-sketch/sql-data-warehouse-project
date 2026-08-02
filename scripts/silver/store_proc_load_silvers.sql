
/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the 'dw_silver' database tables from the 'dw_bronze' database.

Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL load_silver();

===============================================================================
*/

DROP PROCEDURE IF EXISTS load_silver;
DELIMITER //

CREATE PROCEDURE load_silver()
BEGIN


-- ------------------------------
-- Load crm_cust_info
-- -------------------------------
TRUNCATE TABLE dw_silver.crm_cust_info;

INSERT INTO dw_silver.crm_cust_info
( 
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)

SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,

	CASE WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
		 WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
		 ELSE 'n/a'
	END cst_marital_status,
		 
	CASE WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
		 WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM (
 SELECT
 *,
ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
 FROM dw_bronze.crm_cust_info
 ) t WHERE flag_last=1;
 
 
-- -------------------------------  
-- Load crm_prd_info
-- -------------------------------
TRUNCATE TABLE dw_silver.crm_prd_info;

INSERT INTO dw_silver.crm_prd_info (
    prd_id, 
    cat_id, 
    prd_key, 
    prd_nm,
    prd_cost, 
    prd_line, 
    prd_start_dt, 
    prd_end_dt 
)
SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
	SUBSTRING(prd_key,7,LENGTH(prd_key)) AS prd_key,  
	prd_nm,
	COALESCE(NULLIF(prd_cost, ''),0) AS prd_cost,
	CASE UPPER(TRIM(prd_line))
		 WHEN 'M' THEN 'MOUNTAIN' 
		 WHEN 'R' THEN 'Road'
		 WHEN 'S' THEN 'Other Sales'
		 WHEN 'T' THEN 'Touring'
		 ELSE 'n/a'
	END AS prd_line,
	prd_start_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - INTERVAL 1 DAY AS prd_end_dt_test
	FROM dw_bronze.crm_prd_info;
    
-- -------------------------------
-- Load crm_sales_info
-- -------------------------------
TRUNCATE TABLE dw_silver.crm_sales_details;

INSERT INTO dw_silver.crm_sales_details
(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    CASE 
        WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt) != 8 
        THEN NULL
        ELSE CAST(sls_order_dt AS DATE)
    END AS sls_order_dt,

    CASE 
        WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt) != 8 
        THEN NULL
        ELSE CAST(sls_ship_dt AS DATE)
    END AS sls_ship_dt,

    CASE 
        WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt) != 8 
        THEN NULL
        ELSE CAST(sls_due_dt AS DATE)
    END AS sls_due_dt,

    CASE
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0
          OR sls_sales != sls_quantity * ABS(fixed_price)
        THEN sls_quantity * ABS(fixed_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    fixed_price AS sls_price

FROM
(
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,

        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity,0)
            ELSE sls_price
        END AS fixed_price

    FROM dw_bronze.crm_sales_details
) AS x;


-- -------------------------------
-- Load erp_cust_az12
-- -------------------------------
TRUNCATE TABLE dw_silver.erp_cust_az12;

INSERT INTO dw_silver.erp_cust_az12(
cid,
bdate,
gen
)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
     ELSE cid
END cid,
CASE WHEN bdate> CURRENT_DATE() THEN NULL
     ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
     WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'Male'
     ELSE 'n/a'
END AS gen
FROM dw_bronze.erp_cust_az12;


-- -------------------------------
-- Load erp_loc_a101
-- -------------------------------
TRUNCATE TABLE dw_silver.erp_loc_a101;

INSERT INTO dw_silver.erp_loc_a101
(
cid,
country
)
SELECT
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(country)= 'DE' THEN 'Germany'
     WHEN TRIM(country) IN ('US','USA') THEN 'United States'
     WHEN TRIM(Country)= '' THEN 'n/a'
     ELSE TRIM(country)
END AS country
FROM dw_bronze.erp_loc_a101;


-- -------------------------------
-- Load erp_px_cat_g1v2
-- -------------------------------
TRUNCATE TABLE dw_silver.erp_px_cat_g1v2;

INSERT INTO dw_silver.erp_px_cat_g1v2
( 
id,
cat,
subcat,
maintaince
)
SELECT
id,
cat,
subcat,
maintaince
FROM dw_bronze.erp_px_cat_g1v2;

END //

DELIMITER ;
