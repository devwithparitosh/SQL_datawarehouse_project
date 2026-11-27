/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

IF OBJECT_ID('gold.dim_customer','V') IS NOT NULL
	DROP VIEW gold.dim_customer;
GO

CREATE VIEW gold.dim_customer AS 
SELECT 
	ROW_NUMBER() OVER(Order by cst_id) as customer_key,       -- Surrogate key
	sc.cst_id as customer_id,
	sc.cst_key as customer_number ,
	sc.cst_firstname as first_name,
	sc.cst_lastname as last_name,
	sc.cst_marital_status as marital_status ,
	--sc.cst_gndr ,

		CASE 
		WHEN sc.cst_gndr != 'N/A' then sc.cst_gndr
		ELSE COALESCE(src.gen, 'N/A')
	END AS gender,

	sc.cst_create_date as create_date,
	src.bdate as birthday,
	--src.gen,
	srl.country 
FROM silver.crm_customer_info as sc
LEFT JOIN silver.erp_cust as src
	ON	sc.cst_key=src.cid
LEFT JOIN silver.erp_loc as srl
	ON sc.cst_key=srl.cid;

GO


--SELECT * FROM gold.dim_customer


IF OBJECT_ID('gold.dim_products','V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS 
SELECT
	ROW_NUMBER() OVER(ORDER BY sp.prd_start_dt, sp.sls_prd_key) AS product_key,
	sp.prd_id as product_id,
	sp.sls_prd_key as product_number,
	sp.prd_nm product_name,
	sp.cat_id as category_id,
	srg.cat as category,
	srg.subcat as subcategory,
	srg.maintenance,
	sp.prd_cost as product_cost,
	sp.prd_line as product_line,
	CAST(sp.prd_start_dt AS DATE) as start_date
FROM silver.crm_prod_info AS sp
LEFT JOIN silver.erp_px_cat_g1 as srg
	ON sp.cat_id=srg.id
WHERE prd_end_dt IS NULL                --Filter out all historical data

GO
--SELECT * FROM gold.dim_products;

IF OBJECT_ID('gold.fact_sales','V') IS NOT NULL
	DROP VIEW gold.fact_sales;

GO

CREATE VIEW gold.fact_sales AS 
SELECT 
	sd.sls_ord_num as order_number,
	gd.product_number,
	gc.customer_id ,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt ship_date,
	sd.sls_due_dt as due_date,
	sd.sls_price as price,
	sd.sls_quantity as quanity,
	sd.sls_sales as sales 
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customer as gc
	ON sd.sls_cust_id=gc.customer_id
LEFT JOIN gold.dim_products as gd
	ON sd.sls_prd_key=gd.product_number;

--SELECT * FROM gold.fact_sales;


Select * from gold.fact_sales as s
left join gold.dim_customer as c
on c.customer_id=s.customer_id
where c.customer_id is null;

SELECT * FROM gold.fact_sales
SELECT * FROM gold.dim_customer
SELECT * FROM gold.dim_products;