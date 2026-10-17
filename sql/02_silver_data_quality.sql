------------------------------------------------PART 2 ------------------------------------------------
-------------------------------------------------------------------------------------------------------

--------------------------------------------QUESTION #1--------------------------------------------
-- Finds category titles that appear more than once within the same country.
SELECT category_title, COUNT(DISTINCT category_id)
FROM bronze.table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT category_id) > 1;
---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #2--------------------------------------------
-- Finds category title that exist in only one country.
SELECT DISTINCT
    category_title,
    country
FROM
    bronze.table_youtube_category
WHERE
    category_title IN (
        SELECT
            category_title
        FROM
            bronze.table_youtube_category
        GROUP BY
            category_title
        HAVING
            COUNT(DISTINCT country) = 1
    );
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #3--------------------------------------------
-- Selects the unique category IDs for rows where the category title is missing.
SELECT DISTINCT categoryid
FROM silver.table_youtube_final
WHERE category_title IS NULL;
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #4--------------------------------------------

SELECT DISTINCT category_title
FROM silver.table_youtube_final
WHERE categoryId = 29 AND category_title IS NOT NULL;

-- Updates the table to set the category_title to '29' for all rows where it is currently missing.
UPDATE silver.table_youtube_final
SET category_title = 'Nonprofits & Activism'
WHERE category_title IS NULL;
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #5--------------------------------------------
-- Retrieves the video titles for rows where the channel title is missing.
SELECT title
FROM silver.table_youtube_final
WHERE channeltitle IS NULL;
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #6--------------------------------------------
-- Deletes rows with the invalid video_id '#NAME?'.
DELETE FROM silver.table_youtube_final WHERE video_id = '#NAME?';

-- Verifies the deletion by attempting to select the rows that were just removed (should return nothing).
SELECT *
FROM silver.table_youtube_final
WHERE video_id = '#NAME?';
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #7--------------------------------------------
-- Creates a new table containing only the duplicate records from the final table.
CREATE OR REPLACE TABLE silver.table_youtube_duplicates AS
SELECT * EXCLUDE(test_row)
FROM (
    SELECT
    *,
    ROW_NUMBER() OVER (
        PARTITION BY video_id, country, trending_date
        ORDER BY view_count DESC
    ) as test_row
    FROM silver.table_youtube_final
    ORDER BY 1,2,3
)
WHERE test_row != 1;

-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #8--------------------------------------------
-- Deletes all duplicate records from the final table by matching them with the duplicates table.
DELETE FROM silver.table_youtube_final yf
    WHERE EXISTS(
    SELECT 1
    FROM silver.table_youtube_duplicates yd
    WHERE yf.id = yd.id
);
-----------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #9--------------------------------------------

-- Counts the total number of rows remaining in the final table after the duplicates have been removed.
SELECT COUNT(*) = 2597494 FROM silver.table_youtube_final;
-----------------------------------------------------------------------------------------------------

