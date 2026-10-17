------------------------------------------------PART 3 ------------------------------------------------
-------------------------------------------------------------------------------------------------------

--------------------------------------------INIT GOLD SCHEMA-----------------------------------------
--Here we create the gold schema to store the data that will be use for the analysis
CREATE SCHEMA IF NOT EXISTS GOLD;
-----------------------------------------------------------------------------------------------------


--------------------------------------------GOLD TABLE--------------------------------------------
CREATE OR REPLACE TABLE gold.table_youtube_final AS
SELECT *
FROM silver.table_youtube_final;
---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #1--------------------------------------------

--Ranks 'Gaming' videos by views for each country on a specific day and selects the top 3.
WITH videoGamesRanking AS (
    SELECT
        country,
        title,
        channeltitle,
        view_count,
        RANK() OVER (
            PARTITION BY country
            ORDER BY view_count DESC
        ) as RK
    FROM
        gold.table_youtube_final
    WHERE
        category_title = 'Gaming' AND trending_date = '2024-04-01'
)
SELECT
    country,
    title,
    channeltitle,
    view_count,
    RK
FROM
    videoGamesRanking
WHERE
    RK <= 3
ORDER BY
    country, RK;


---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #2--------------------------------------------

--Counts distinct videos mentioning 'BTS' in the title, grouped by country.
SELECT 
    country,
    COUNT(DISTINCT video_id) as CT
FROM gold.table_youtube_final
WHERE UPPER(title) LIKE('%BTS%')
GROUP BY country
ORDER BY 2 DESC;


---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #3--------------------------------------------

--Identifies the single most-viewed video for each country and month in 2024.
WITH youtube_data_from_2024 AS (
    SELECT 
        *,
        DATE_TRUNC('MONTH', trending_date)::DATE AS year_month,
        CASE
            WHEN view_count = 0 THEN 0
            ELSE ROUND(likes / view_count * 100, 2)
        END AS likes_ratio
    FROM 
        gold.table_youtube_final
    WHERE 
        YEAR(trending_date) = 2024
),
youtube_ranked_data_from_2024 AS (
    SELECT 
        *,
        DENSE_RANK() OVER (
            PARTITION BY country, year_month
            ORDER BY view_count DESC
        ) AS RK
    FROM 
        youtube_data_from_2024
)
SELECT
    country,
    year_month,
    title,
    channeltitle,
    category_title,
    view_count,
    likes_ratio
FROM 
    youtube_ranked_data_from_2024
WHERE 
    RK = 1
ORDER BY 
    2, 1;


---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #4--------------------------------------------


-- Since 2022, finds the top video category per country and its percentage of that country's total videos.
WITH total_dist_videos_per_country_2022 AS (
    SELECT
        country,
        COUNT(DISTINCT video_id) AS total_country_video
    FROM
        gold.table_youtube_final
    WHERE
        YEAR(trending_date) >= 2022
    GROUP BY
        country
),

total_dist_videos_per_country_category_2022 AS (
    SELECT
        country,
        category_title,
        COUNT(DISTINCT video_id) AS total_category_video
    FROM
        gold.table_youtube_final
    WHERE
        YEAR(trending_date) >= 2022
    GROUP BY
        country,
        category_title
),

merge_data_2022 AS (
    SELECT
        cct.country,
        cct.category_title,
        cct.total_category_video,
        c.total_country_video
    FROM
        total_dist_videos_per_country_category_2022 AS cct
        LEFT JOIN total_dist_videos_per_country_2022 AS c ON cct.country = c.country
),

ranked_data AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY
                country
            ORDER BY
                total_category_video DESC
        ) AS rk
    FROM
        merge_data_2022
)
SELECT
    country,
    category_title,
    total_category_video,
    total_country_video,
    CASE
        WHEN total_country_video = 0 OR total_country_video IS NULL 
        THEN 0
        ELSE ROUND((total_category_video / total_country_video) * 100, 2)
    END AS percentage
FROM
    ranked_data
WHERE
    rk = 1
ORDER BY
    category_title,
    country;


---------------------------------------------------------------------------------------------------


--------------------------------------------QUESTION #5--------------------------------------------

-- Finds the channel with the most distinct videos overall.
SELECT
    channeltitle,
    COUNT(DISTINCT video_id) AS total_count
FROM
    gold.table_youtube_final
GROUP BY
    channeltitle
ORDER BY
    2
DESC
LIMIT 1;

---------------------------------------------------------------------------------------------------