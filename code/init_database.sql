USE master;
GO

--Create Database 'Datawarehouse'
Create Database Datawarehouse;
GO

Use Datawarehouse;
GO

Create SCHEMA bronze;
GO

Create SCHEMA silver;
GO

Create SCHEMA gold;
GO


-- CHECK BEFORE CREATEING a TABLE EXISTS OR NOT .
IF OBJECT_ID('bronze.crm_customer_info' , 'U') IS NOT NULL
	DROP TABLE bronze.crm_customer_info;

-- CREATE A TABLE FOR BRONZE LAYER
CREATE TABLE bronze.crm_customer_info(
	cst_id INT,
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gndr NVARCHAR(50),
	cst_create_date DATE
);

IF OBJECT_ID('bronze.crm_prod_info','U') IS NOT NULL
	DROP TABLE bronze.crm_prod_info;

/* Create a SQL DDL Scripts for all CSV files 
in CRM and ERP System. */

CREATE TABLE bronze.crm_prod_info(
	prd_id INT,
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATETIME,
	prd_end_dt DATETIME
);

IF OBJECT_ID('bronze.crm_sales_details','U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT ,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT 
);

IF OBJECT_ID('bronze.erp_loc','U') IS NOT NULL
	DROP TABLE bronze.erp_loc;

CREATE TABLE bronze.erp_loc (
	cid NVARCHAR(50),
	country NVARCHAR(50)
);

IF OBJECT_ID('bronze.erp_cust','U') IS NOT NULL
	DROP TABLE bronze.erp_cust;

CREATE TABLE bronze.erp_cust(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50)
);

IF OBJECT_ID('bronze.erp_px_cat_g1','U') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1;

CREATE TABLE bronze.erp_px_cat_g1(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50)
);


CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME , @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time=GETDATE();             -- TO CHECK THE LOAD TIME OF WHOLE PROCEDURE

		PRINT 'LOADING BRONZE LAYER';

		SET @start_time=GETDATE();
		PRINT '>> TABLE :bronze.crm_customer_info';
		TRUNCATE Table bronze.crm_customer_info;       --Empty the table first than ....

		-- LOAD THE DATA INTO THE TABLE via source file path.
		BULK INSERT bronze.crm_customer_info
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_crm\customer_info.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT '>> LOAD Duration : '+ CAST(DATEDIFF(second ,@start_time,@end_time) AS NVARCHAR) + ' seconds';

		-- SELECT * FROM bronze.crm_customer_info;
		PRINT '------------------------';

		PRINT '>> LOAD TABLE :bronze.crm_prod_info';
		SET @start_time=GETDATE();
		TRUNCATE TABLE bronze.crm_prod_info;
		BULK INSERT bronze.crm_prod_info
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_crm\prod_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT 'LOAD DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) +' seconds';

		-- SELECT * FROM bronze.crm_prod_info;
		PRINT '------------------------';

		SET @start_time=GETDATE();
		PRINT 'LOAD TABLE : bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT 'LOAD DUARTION :'+ CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) +' seconds';

		-- SELECT * FROM bronze.crm_sales_details;
		PRINT '------------------------';

		SET @start_time=GETDATE();
		PRINT 'LOAD TABLE : bronze.erp_loc'
		TRUNCATE TABLE bronze.erp_loc;
		BULK INSERT bronze.erp_loc
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time=GETDATE();
		PRINT 'LOAD DURATION :' + CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + ' seconds';
		
		-- SELECT * FROM bronze.erp_loc;
		PRINT '------------------------';

		set @start_time=GETDATE();
		PRINT 'LOAD TABLE : bronze.erp_cust';
		TRUNCATE TABLE bronze.erp_cust;
		BULK INSERT bronze.erp_cust
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time=GETDATE();

		PRINT 'LOAD DUARTION :' + CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) +' seconds';
		-- SELECT * FROM bronze.erp_cust;
		PRINT '------------------------';

		SET @start_time=GETDATE();
		PRINT 'LOAD TABLE : bronze.erp_px_cat_g1';
		TRUNCATE TABLE bronze.erp_px_cat_g1;
		BULK INSERT bronze.erp_px_cat_g1
		FROM 'C:\Users\parit\Downloads\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW =2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time=GETDATE();

		PRINT 'LOAD DUARTION :' + CAST(DATEDIFF(second,@start_time,@end_time) as NVARCHAR) + 'seconds';

		-- SELECT * FROM bronze.erp_px_cat_g1;
		PRINT '------------------------';

		SET @batch_end_time=GETDATE();

		PRINT 'Total Duration : ' +CAST(DATEDIFF(SECOND ,@batch_start_time,@batch_end_time) AS NVARCHAR) +' seconds';
	END TRY 
	BEGIN CATCH
		PRINT '=======================================';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_NUMBER() AS NVARCHAR );
		PRINT 'Error State' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '=======================================';
	END CATCH
END

EXEC bronze.load_bronze;