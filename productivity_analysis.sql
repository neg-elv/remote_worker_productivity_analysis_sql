-- Filename: productivity_analysis.sql
-- Dataset: remote_worker_productivity
-- Purpose: This SQL script analyzes how factors like focus_time, tool_usage and productivity vary based on  age group and location type

-- ===================================
-- LOCATION_BASED ANALYSIS
-- ===================================

WITH location_type AS (
-- Aggregate average metrics by location_type
SELECT 
	location_type,
    (SELECT TRUNCATE(AVG(productivity_score), 2) FROM remote_worker_productivity WHERE location_type = rwp.location_type) AS avg_productivity_score,
    (SELECT TRUNCATE(AVG(tool_usage_frequency), 2) FROM remote_worker_productivity WHERE location_type = rwp.location_type) AS avg_tool_usage,
    (SELECT TRUNCATE(AVG(ai_assisted_planning), 2) FROM remote_worker_productivity WHERE location_type = rwp.location_type) AS avg_ai_assisted,
    (SELECT TRUNCATE(AVG(average_daily_work_hours), 2) FROM remote_worker_productivity WHERE location_type = rwp.location_type) AS avg_work_hour
FROM remote_worker_productivity rwp
GROUP BY location_type)
-- Compare each location_type to the first one for % change in metrics
SELECT 
	location_type,
    avg_productivity_score,
    avg_tool_usage,
    ROUND((avg_tool_usage - FIRST_VALUE(avg_tool_usage) OVER (ORDER BY avg_tool_usage)) /
    FIRST_VALUE(avg_tool_usage) OVER (ORDER BY avg_tool_usage)* 100,2) AS avg_tool_usage_percent,
    avg_ai_assisted,
    ROUND((avg_work_hour - FIRST_VALUE(avg_work_hour) OVER ( ORDER BY avg_work_hour)) /
    FIRST_VALUE(avg_work_hour) OVER ( ORDER BY avg_work_hour) * 100, 2) AS avg_work_hour_percent,
    avg_work_hour
FROM location_type;

-- ================================
-- AGE_BASED ANALYSIS
-- ================================

WITH age_summary AS (
-- Create age ranges for grouping people by age
SELECT 
	CASE 
		WHEN age BETWEEN 20 AND 25 THEN '20_25_age'
        WHEN age BETWEEN 25 AND 30 THEN '25_30_age'
        WHEN age BETWEEN 30 AND 35 THEN '30_35_age'
        WHEN age BETWEEN 35 AND 40 THEN '35_40_age'
        WHEN age BETWEEN 40 AND 50 THEN '40_50_age'
        WHEN age BETWEEN 50 AND 60 THEN '50_60_age'
        ELSE 'OTHER_AGE'
	END AS age_range,
-- Calculate total people and average metrics by age group
    COUNT(*) AS total_people,

	TRUNCATE(AVG(average_daily_work_hours),2) AS avg_daily_hours_worked,
    TRUNCATE(AVG(experience_years),2) AS avg_years_of_experience,
    TRUNCATE(AVG(focus_time_minutes),2) AS avg_focus_time,
    TRUNCATE(AVG(tool_usage_frequency),2) AS avg_tool_usage,
    TRUNCATE(AVG(productivity_score),2) AS avg_productivity_score
FROM remote_worker_productivity
WHERE experience_years <= age - 15
GROUP BY age_range
)
-- Calculate % difference compared to the first age group(based on age_range sorting)
SELECT 
	age_range,
    total_people,
    avg_years_of_experience,
		ROUND((avg_years_of_experience - FIRST_VALUE(avg_years_of_experience) OVER (ORDER BY age_range)) /
     FIRST_VALUE(avg_years_of_experience) OVER (ORDER BY age_range) * 100, 2) AS diff_experience_percent,
    avg_focus_time,
		ROUND((avg_focus_time - FIRST_VALUE(avg_focus_time) OVER (ORDER BY age_range)) /
     FIRST_VALUE(avg_focus_time) OVER (ORDER BY age_range) * 100, 2) AS diff_focus_percent,
    avg_tool_usage,
		ROUND((avg_tool_usage - FIRST_VALUE(avg_tool_usage) OVER (ORDER BY age_range)) /
     FIRST_VALUE(avg_tool_usage) OVER (ORDER BY age_range) * 100, 2) AS diff_tool_usage_percent,
    avg_productivity_score,
		ROUND((avg_productivity_score - FIRST_VALUE(avg_productivity_score) OVER (ORDER BY age_range)) /
     FIRST_VALUE(avg_productivity_score) OVER (ORDER BY age_range) * 100, 2) AS productivity_diff_percent
FROM age_summary;
