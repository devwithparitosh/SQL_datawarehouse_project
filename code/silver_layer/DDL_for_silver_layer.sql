USE Datawarehouse;
GO

-- TO ANALYSIS THE TABLE FOR FORGIEN KEY FIND OUT THE REALTION BETWEEN THEM
SELECT * FROM bronze.crm_customer_info;
SELECT * FROM bronze.crm_prod_info;
SELECT * FROM bronze.crm_sales_details;

SELECT * FROM bronze.erp_cust;
SELECT * FROM bronze.erp_loc;
SELECT * FROM bronze.erp_px_cat_g1;

IF OBJECT_ID ('silver.crm_customer_info','U') IS NOT NULL
	DROP TABLE silver.crm_customer_info;

CREATE TABLE silver.crm_customer_info (
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()            -- to store the creation date of the data insert
);

IF OBJECT_ID('silver.crm_prod_info','U') IS NOT NULL
	DROP TABLE silver.crm_prod_info;

CREATE TABLE silver.crm_prod_info(
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATETIME,
	prd_end_dt DATETIME,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT ,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE() 
);

IF OBJECT_ID('silver.erp_loc','U') IS NOT NULL
	DROP TABLE silver.erp_loc;

CREATE TABLE silver.erp_loc (
	cid NVARCHAR(50),
	country NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_cust','U') IS NOT NULL
	DROP TABLE silver.erp_cust;

CREATE TABLE silver.erp_cust(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

IF OBJECT_ID('silver.erp_px_cat_g1','U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1;

CREATE TABLE silver.erp_px_cat_g1(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
