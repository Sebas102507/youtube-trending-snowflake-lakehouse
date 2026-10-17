------------------------------------------------PART 4 ------------------------------------------------
-------------------------------------------------------------------------------------------------------


--------------------------------------------CREATE SOURCE TABLE FOR THE ANALYSIS--------------------


CREATE OR REPLACE TABLE gold.table_youtube_analysis_global AS
SELECT
    DATE_TRUNC('MONTH', trending_date)::DATE AS trending_month,
    category_title,
    COUNT(DISTINCT video_id) AS trending_videos_count,
    SUM(view_count) AS total_view_count,
    AVG(view_count) AS avg_views,
    SUM(likes) AS total_likes,
    AVG(likes) AS avg_likes,
    COUNT(DISTINCT channelid) AS unique_channels,
    AVG(DATEDIFF('day', publishedat::DATE, trending_date)) AS avg_days_to_trend,
    AVG(likes::float / NULLIF(view_count, 0)) AS avg_engagement_ratio
FROM
    gold.table_youtube_final
WHERE
    category_title NOT IN ('Music', 'Entertainment')
    AND YEAR(trending_date) >= 2022
GROUP BY
    trending_month,
    category_title
ORDER BY
    trending_month ASC,
    unique_channels ASC;
SELECT * FROM gold.table_youtube_analysis_global;



CREATE OR REPLACE TABLE gold.table_youtube_analysis_source_by_country AS
SELECT
    DATE_TRUNC('MONTH', trending_date)::DATE AS trending_month,
    country,
    category_title,
    COUNT(DISTINCT video_id) AS trending_videos_count,
    SUM(view_count) AS total_view_count,
    AVG(view_count) AS avg_views,
    SUM(likes) AS total_likes,
    AVG(likes) AS avg_likes,
    COUNT(DISTINCT channelid) AS unique_channels,
    AVG(DATEDIFF('day', publishedat::DATE, trending_date)) AS avg_days_to_trend,
    AVG(likes::float / NULLIF(view_count, 0)) AS avg_engagement_ratio
FROM
    gold.table_youtube_final
WHERE
    category_title NOT IN ('Music', 'Entertainment') 
    AND YEAR(trending_date) >= 2022
GROUP BY
    trending_month,
    country,
    category_title
ORDER BY
    country ASC,
    trending_month ASC,
    unique_channels ASC;

SELECT * FROM gold.table_youtube_analysis_source_by_country;


-----------------------------------------------------------------------------------------------------


--------------------------------------------CREATE VIEWS---------------------------------------------

-- CREATE VIEWS FROM THE GLOBAL ANALYSIS TABLE

-- View for trending videos count by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_trending_videos_count AS
SELECT 
    trending_month,
    category_title,
    trending_videos_count
FROM gold.table_youtube_analysis_global;

-- View for average views by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_avg_views AS
SELECT 
    trending_month,
    category_title,
    avg_views
FROM gold.table_youtube_analysis_global;

-- View for total view count by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_total_view_count AS
SELECT 
    trending_month,
    category_title,
    total_view_count
FROM gold.table_youtube_analysis_global;

-- View for average likes by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_avg_likes AS
SELECT 
    trending_month,
    category_title,
    avg_likes
FROM gold.table_youtube_analysis_global;

-- View for total likes by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_total_likes AS
SELECT 
    trending_month,
    category_title,
    total_likes
FROM gold.table_youtube_analysis_global;

-- View for unique channels by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_unique_channels AS
SELECT 
    trending_month,
    category_title,
    unique_channels
FROM gold.table_youtube_analysis_global;

-- View for average days to trend by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_avg_days_to_trend AS
SELECT 
    trending_month,
    category_title,
    avg_days_to_trend
FROM gold.table_youtube_analysis_global;

-- View for average engagement ratio by month and category
CREATE OR REPLACE VIEW gold.v_yt_global_avg_engagement_ratio AS
SELECT 
    trending_month,
    category_title,
    avg_engagement_ratio
FROM gold.table_youtube_analysis_global;


-- CREATE VIEWS FROM THE COUNTRY-SPECIFIC ANALYSIS TABLE


-- View for average views by country, month, and category
CREATE OR REPLACE VIEW gold.v_yt_country_avg_views AS
SELECT 
    country,
    trending_month,
    category_title,
    avg_views
FROM gold.table_youtube_analysis_source_by_country;

-- View for total view count by country, month, and category
CREATE OR REPLACE VIEW gold.v_yt_country_total_view_count AS
SELECT 
    country,
    trending_month,
    category_title,
    total_view_count
FROM gold.table_youtube_analysis_source_by_country;

-- View for average likes by country, month, and category
CREATE OR REPLACE VIEW gold.v_yt_country_avg_likes AS
SELECT 
    country,
    trending_month,
    category_title,
    avg_likes
FROM gold.table_youtube_analysis_source_by_country;

-- View for total likes by country, month, and category
CREATE OR REPLACE VIEW gold.v_yt_country_total_likes AS
SELECT 
    country,
    trending_month,
    category_title,
    total_likes
FROM gold.table_youtube_analysis_source_by_country;

-----------------------------------------------------------------------------------------------------
