SELECT * FROM bronze.crm_customer_info;
/*
-- Find the duplicate in primary key 
SELECT 
	cst_id,
	COUNT(*)
FROM bronze.crm_customer_info
GROUP BY cst_id
HAVING COUNT(*)>1 OR cst_id IS NULL;

-- Manage the duplicate value of primary key based on the individual duplicate
-- suppose : the lastest date has the relivant value compare to other duplicate
SELECT 
	*
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	from bronze.crm_customer_info
	WHERE cst_id IS NOT NULL
)t WHERE flag_last=1;

--check the unwanted spaces.
SELECT
	cst_firstname
FROM bronze.crm_customer_info
where cst_firstname != TRIM(cst_firstname);

*/

-- Write a central logic to combine all the logic AND INSERT INTO THE TABLE OF SILVER LAYER
INSERT INTO silver.crm_customer_info(
	cst_id ,
	cst_key ,
	cst_firstname ,
	cst_lastname ,
	cst_marital_status ,
	cst_gndr ,
	cst_create_date)
SELECT 
	cst_id,
	cst_key,

	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,

	CASE
		WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
		ELSE 'N/A'
	END AS cst_marital_status,          -- data Normalization & Standardization

	CASE	
		WHEN UPPER(cst_gndr)='M' THEN 'Male'
		WHEN UPPER(cst_gndr)='F' THEN 'Female'
		ELSE 'N/A'                       -- handling the missing values 
	END AS cst_gndr,

	cst_create_date
FROM(
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flags
	FROM bronze.crm_customer_info
	WHERE cst_id IS NOT NULL
)t WHERE flags=1;                         -- removing duplicates


-- select * from silver.crm_customer_info

-- ================================================================================

SELECT * FROM bronze.crm_prod_info;

/*
-- STEP 1:- check for Nulls or DUPLICATE IN THE PRIMARY KEY.
SELECT 
	prd_id,
	COUNT(*)
FROM bronze.crm_prod_info
GROUP BY prd_id
HAVING COUNT(prd_id) > 1 OR prd_id IS NULL;

-- STEP 2:- Analysis the other parameter for the null and factor of the attribute of the column like (cost is not null --> it should be a 0 ).
-- STEP 3:- exract the match part of the primary key to stablished the relation between other table.

SELECT DISTINCT prd_line
from bronze.crm_prod_info;

*/



IF OBJECT_ID('silver.crm_prod_info','U') IS NOT NULL
	DROP TABLE silver.crm_prod_info;

CREATE TABLE silver.crm_prod_info(
	prd_id INT,
	cat_id NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATETIME,
	prd_end_dt DATETIME,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);                    -- BECAUSE ADD NEW COLUMN IN THE TABLE

INSERT INTO silver.crm_prod_info(
	prd_id ,
	cat_id ,
	sls_prd_key ,
	prd_nm ,
	prd_cost ,
	prd_line ,
	prd_start_dt,
	prd_end_dt
)
SELECT
	prd_id,
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) AS sls_prd_key,
	prd_nm,
	ISNULL(prd_cost,0) AS prd_cost,               -- NULL HANDLING

	CASE
		WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mountain'
		WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
		WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
		WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
		ELSE 'N/A'
	END AS prd_line,

	CAST(prd_start_dt AS DATE) AS prd_start_dt,
	CAST(LEAD(prd_end_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS date) AS prd_end_dt
FROM bronze.crm_prod_info;

-- SELECT * FROM silver.crm_prod_info;

-- =====================================================================================

SELECT * FROM bronze.crm_sales_details;
/*
SELECT 
	sls_ord_num ,
	sls_prd_key ,
	sls_cust_id ,
	sls_order_dt ,
	sls_ship_dt ,
	sls_due_dt  ,
	sls_sales ,
	sls_quantity ,
	sls_price
FROM bronze.crm_sales_details
where sls_prd_key not in (select sls_prd_key from silver.crm_prod_info);              -- too check whether it able to connect .
*/

/*
-- Step 1:- Analysis the whole table then find out the uneven column which value is not in proper format or required the changes .

-- CHECK THE INVALID DATES

SELECT 
	NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt<=0
OR LEN(sls_due_dt) !=8
OR sls_due_dt>20250101
OR sls_due_dt<19000101;

-- STEP 2:- CHECK FOR INVAILD DATES ORDERS
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;


-- ============= Business Rule ============= 
 total Sales = Quantity * prICE 
   >>  -VE,0,NULL ARE NOT ALLOWED 

SELECT DISTINCT 
	sls_sales,
	sls_quantity,
	sls_price
from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
	OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0
ORDER BY sls_sales,
		sls_quantity,
		sls_price;

--HOW TO FIX THE QUALITY OF THE DATA 
--RULE :-
		1) IF Sales is -ve , 0 or null , dervie it using quantity and price.
		2) IF PRice is 0 or null, calculate it using Sales and Quanity.
		3) IF Price is negative , convert it to a positive value.
*/
IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt DATE,                   -- UPDATE INT TO DATE
	sls_ship_dt DATE,
	sls_due_dt DATE ,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

INSERT INTO silver.crm_sales_details(
	sls_ord_num ,
	sls_prd_key ,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt ,
	sls_due_dt ,
	sls_sales ,
	sls_quantity ,
	sls_price
)
SELECT 
	sls_ord_num ,
	sls_prd_key ,
	sls_cust_id ,
	CASE 
		WHEN sls_order_dt =0 OR LEN(sls_order_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS date)
	END AS sls_order_dt,

	CASE
		WHEN sls_ship_dt =0 OR LEN(sls_ship_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS varchar) AS date) 
	END AS sls_ship_dt,

	CASE 
		WHEN sls_due_dt=0 OR LEN(sls_due_dt) !=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS varchar) AS date) 
	END AS sls_due_dt,

	CASE
		WHEN sls_sales != sls_quantity * ABS(sls_price) 
			OR sls_sales = NULL OR sls_sales <=0  THEN sls_quantity*ABS(sls_price)
		ELSE sls_sales
	END AS sls_sales,
		
	sls_quantity ,

	CASE 
		WHEN sls_price IS NULL OR sls_price <=0
			THEN sls_sales/ NULLIF(sls_quantity,0)
		ELSE sls_price
	END AS sls_price
FROM bronze.crm_sales_details;

-- SELECT * FROM silver.crm_sales_details;
-- ===============================================================================================

SELECT * FROM bronze.erp_cust;

SELECT * FROM bronze.erp_loc;
SELECT * FROM bronze.erp_px_cat_g1;