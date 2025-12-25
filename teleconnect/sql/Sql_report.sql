-- Create a detailed call-level performance view with timestamps, duration, revenue, signal, and validation info
CREATE VIEW reports.call_performance_report AS
SELECT
    call_id,
    customer_id,
    customer_segment,
    network_type,
    call_type,
    tower_id,

    DATE(call_timestamp) AS call_date,           -- Extract just the date from the timestamp
    call_timestamp,                               -- Original timestamp of the call
    EXTRACT(HOUR FROM call_timestamp) AS call_hour,  -- Hour of the day
    TO_CHAR(call_timestamp, 'Day') AS day_of_week,   -- Day name
    EXTRACT(MONTH FROM call_timestamp) AS call_month,
    EXTRACT(YEAR FROM call_timestamp) AS call_year,

    call_duration_seconds,
    call_duration_seconds / 60.0 AS call_duration_minutes, -- Duration in minutes
    data_usage_mb,
    revenue_naira,
    revenue_naira / NULLIF(call_duration_seconds, 0) AS revenue_per_call, -- Avoid divide by zero

    signal_strength_dbm,
    signal_quality,

    call_success,
    signal_valid,
    phone_valid,
    roaming
FROM staging.teleconnect_cdr;



-- Aggregate revenue and call duration per customer
CREATE VIEW reports.customer_revenue_report AS
SELECT
    customer_id,
    customer_segment,
    COUNT(call_id) AS total_calls,                   -- Total calls per customer
    SUM(revenue_naira) AS total_revenue_naira,       -- Total revenue per customer
    ROUND(AVG(revenue_naira)::NUMERIC, 2) AS avg_revenue_per_call,
    ROUND(AVG(call_duration_seconds / 60.0)::NUMERIC, 2) AS avg_call_duration_minutes
FROM staging.teleconnect_cdr
GROUP BY customer_id, customer_segment;




-- Aggregate network performance: success rate and average signal strength per network type
CREATE VIEW reports.network_performance_report AS
SELECT
    network_type,
    COUNT(call_id) AS total_calls,
    SUM(CASE WHEN call_success = true THEN 1 ELSE 0 END) AS successful_calls,
    ROUND(
        (100.0 * SUM(CASE WHEN call_success = true THEN 1 ELSE 0 END) / COUNT(*))::NUMERIC,
        2
    ) AS success_rate_pct,
    ROUND(AVG(signal_strength_dbm)::NUMERIC, 2) AS avg_signal_strength_dbm
FROM staging.teleconnect_cdr
GROUP BY network_type;



-- Aggregate tower performance: total calls, average signal, and call success rate per tower
CREATE VIEW reports.tower_performance_report AS
SELECT
    tower_id,
    COUNT(call_id) AS total_calls,
    ROUND(AVG(signal_strength_dbm)::NUMERIC, 2) AS avg_signal_strength,
    ROUND(
        (100.0 * SUM(CASE WHEN call_success = true THEN 1 ELSE 0 END) / COUNT(*))::NUMERIC,
        2
    ) AS call_success_rate_pct
FROM staging.teleconnect_cdr
GROUP BY tower_id;


-- Aggregate revenue and calls over time by year, month, and day
CREATE VIEW reports.time_revenue_report AS
SELECT
    year_number,
    month_name,
    day_name,
    COUNT(call_id) AS total_calls,
    SUM(revenue_naira) AS total_revenue_naira
FROM fact.teleconnect t
LEFT JOIN dim.date d ON t.date_sk = d.date_sk 
GROUP BY year_number, month_name, day_name;






-- Aggregate call success and revenue per signal quality
CREATE VIEW reports.signal_quality_report AS
SELECT
    signal_quality,
    COUNT(call_id) AS total_calls,
    ROUND(
        (100.0 * SUM(CASE WHEN call_success = true THEN 1 ELSE 0 END) / COUNT(*))::NUMERIC,
        2
    ) AS success_rate_pct,
    ROUND(AVG(revenue_naira)::NUMERIC, 2) AS avg_revenue_naira
FROM staging.teleconnect_cdr
GROUP BY signal_quality;






