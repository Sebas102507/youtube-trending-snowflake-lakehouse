------------------------------------------------PART 1 ------------------------------------------------
-------------------------------------------------------------------------------------------------------

--------------------------------------------INIT DATABASE--------------------------------------------
--Here we create the database that will be used for the first assignment.
CREATE DATABASE IF NOT EXISTS assignment_1;
--Here we especify that we want to use the assignment_1 database.
USE DATABASE assignment_1;

--Here we create the bronze schema to store the raw tables
CREATE SCHEMA IF NOT EXISTS BRONZE;
CREATE SCHEMA IF NOT EXISTS SILVER;
-----------------------------------------------------------------------------------------------------


--------------------------------------------INIT STAGES----------------------------------------------

--Here we create or replace(Update) the stage for youtube trending data
CREATE OR REPLACE STAGE stage_assignment_youtube_trending
URL = 'azure://utsbdesebas.blob.core.windows.net/assignment-1/youtube_trending/'
CREDENTIALS=(azure_sas_token='<YOUR_AZURE_SAS_TOKEN>');
--Here we list the files that are accessed by the stage
LIST @stage_assignment_youtube_trending;

--Here we create or replace(Update) the stage for youtube trending data
CREATE OR REPLACE STAGE stage_assignment_youtube_category
URL = 'azure://utsbdesebas.blob.core.windows.net/assignment-1/youtube-category/'
CREDENTIALS=(azure_sas_token='<YOUR_AZURE_SAS_TOKEN>');
--Here we list the files that are accessed by the stage
LIST @stage_assignment_youtube_category;
-----------------------------------------------------------------------------------------------------


--------------------------------------------INIT FILES FORMATS-------------------------------------

--Create the file format to correctly read the csv files
CREATE OR REPLACE FILE FORMAT file_format_csv
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('\\N', 'NULL', 'NUL', '')
FIELD_OPTIONALLY_ENCLOSED_BY = '"';


CREATE OR REPLACE FILE FORMAT file_format_json
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE
  NULL_IF = ('\\N', 'NULL', 'NUL', '');
  

-----------------------------------------------------------------------------------------------------


--------------------------------------------CREATE EXTERNAL TABLES-------------------------------------
-- Create or replace the youtube trending external table with csv format (This reads all the files whithin the directory in azure)
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending
(
    video_id       STRING        AS (value:c1::STRING),
    title          STRING        AS (value:c2::STRING),
    publishedAt    TIMESTAMP_NTZ AS (value:c3::TIMESTAMP_NTZ),
    channelId      STRING        AS (value:c4::STRING),
    channelTitle   STRING        AS (value:c5::STRING),
    categoryId     NUMBER        AS (value:c6::NUMBER),
    trending_date  DATE          AS (value:c7::DATE),
    view_count     NUMBER        AS (value:c8::NUMBER),
    likes          NUMBER        AS (value:c9::NUMBER),
    dislikes       NUMBER        AS (value:c10::NUMBER),
    comment_count  NUMBER        AS (value:c11::NUMBER)
)
WITH LOCATION = @stage_assignment_youtube_trending
FILE_FORMAT = file_format_csv;

-- Gets the first 10 elements of the table
SELECT * FROM assignment_1.public.ex_table_youtube_trending LIMIT 10;

-- Create or replace the youtube category external table with json format (This reads all the files whithin the directory in azure)
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_category
WITH LOCATION = @stage_assignment_youtube_category
FILE_FORMAT = file_format_json;

-- Gets the first 10 elements of the table
SELECT * FROM assignment_1.public.ex_table_youtube_category LIMIT 10;

-----------------------------------------------------------------------------------------------------


--------------------------------------------CREATE TABLES----------------------------------------------

--Creating the trending table from the external table
CREATE OR REPLACE TABLE bronze.table_youtube_trending AS
SELECT 
    video_id,
    title,
    publishedat,
    channelid,
    channeltitle,
    categoryid,
    trending_date,
    view_count,
    likes,
    dislikes,
    REGEXP_SUBSTR(METADATA$FILENAME, '([A-Z]{2})_youtube_trending_data.csv', 1, 1, 'e') AS country,
FROM ex_table_youtube_trending;

-- Gets the first 10 elements of the table
SELECT * FROM bronze.table_youtube_trending LIMIT 10;


--Creating the category table from the external table
CREATE OR REPLACE TABLE bronze.table_youtube_category AS
SELECT
    REGEXP_SUBSTR(METADATA$FILENAME, '([A-Z]{2})_category_id.json', 1, 1, 'e') AS country,
    f.value:id::STRING AS category_id,
    f.value:snippet.title::STRING AS category_title
FROM
    ex_table_youtube_category,
    LATERAL FLATTEN(input => VALUE:items) f;

-- Gets the first 10 elements of the table
SELECT * FROM bronze.table_youtube_category LIMIT 10;


--Creating the final table from the trending and category tables
CREATE OR REPLACE TABLE silver.table_youtube_final AS
SELECT
    UUID_STRING() AS id,
    tr.*,
    ct.category_title
FROM
    bronze.table_youtube_trending AS tr
LEFT JOIN
    bronze.table_youtube_category AS ct
    ON tr.categoryid = ct.category_id AND tr.country = ct.country;


-- Gets the first 10 elements of the table
SELECT * FROM silver.table_youtube_final LIMIT 10;

-- Count of the table
SELECT COUNT(*) FROM silver.table_youtube_final;

describe table silver.table_youtube_final;

-----------------------------------------------------------------------------------------------------
