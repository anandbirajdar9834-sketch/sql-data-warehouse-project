
/*
===============================================================================
Database Initialization Script
===============================================================================
Script Purpose:
    This script creates the Data Warehouse databases for the Medallion
    Architecture.

    The script drops the existing databases (if they exist) and recreates
    the Bronze, Silver, and Gold databases.

Databases:
    - dw_bronze : Raw source data
    - dw_silver : Cleansed and transformed data
    - dw_gold   : Business-ready analytical data
===============================================================================
*/

-- ---------------------------------------------------------------------------
-- Drop Existing Databases
-- ---------------------------------------------------------------------------

DROP DATABASE IF EXISTS dw_bronze;
DROP DATABASE IF EXISTS dw_silver;
DROP DATABASE IF EXISTS dw_gold;

-- ---------------------------------------------------------------------------
-- Create Databases
-- ---------------------------------------------------------------------------

CREATE DATABASE dw_bronze;

CREATE DATABASE dw_silver;

CREATE DATABASE dw_gold;
