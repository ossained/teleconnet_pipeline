---Creating schemas 
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dim;
CREATE SCHEMA IF NOT EXISTS fact;
CREATE SCHEMA IF NOT EXISTS reports;
 --Moving the table from public to staing
 ALTER TABLE public.teleconnect_cdr
SET SCHEMA staging;


---Creating dimention tables under the dim schema
---dim customer
CREATE TABLE dim.customers AS 
SELECT DISTINCT
	ROW_NUMBER () OVER (ORDER BY customer_id ) as customer_sk,
	customer_id,
	phone_number,
	phone_valid,
	call_type
FROM staging.teleconnect_cdr
WHERE customer_id IS NOT NULL
GROUP BY customer_id,phone_valid,call_type,phone_number;



--dim tower
CREATE TABLE dim.tower AS
SELECT DISTINCT
	ROW_NUMBER () OVER (ORDER BY tower_id ) as tower_sk,
	tower_id,
	signal_strength_dbm,
	signal_valid
FROM staging.teleconnect_cdr
WHERE tower_id IS NOT NULL
GROUP BY tower_id,signal_strength_dbm,signal_valid;



--dim network
CREATE TABLE dim.network AS
SELECT DISTINCT
	ROW_NUMBER () OVER (ORDER BY network_type ) as network_type_sk,
	network_type,
	roaming,
	signal_quality
FROM staging.teleconnect_cdr
WHERE network_type IS NOT NULL
GROUP BY network_type,signal_quality,roaming;


--dim time


CREATE TABLE dim.date AS
SELECT 
    TO_CHAR(date_val, 'YYYYMMDD')::INTEGER AS date_sk,  -- unique per day
    date_val AS full_date,
    TRIM(TO_CHAR(date_val,'DAY')) AS day_name,
    TRIM(TO_CHAR(date_val,'MONTH')) AS month_name,
    EXTRACT(MONTH FROM date_val) AS month_number,
    CASE 
        WHEN EXTRACT(DOW FROM date_val) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    EXTRACT(YEAR FROM date_val) AS year_number
FROM generate_series(
        '2024-01-01'::DATE,
        '2024-12-31'::DATE,
        '1 day'  -- generates daily timestamps
     ) AS date_val;
	 

	
---create fact table
CREATE TABLE fact.teleconnect AS
SELECT DISTINCT 
	ROW_NUMBER () OVER (ORDER BY st.call_timestamp) AS call_timestamp_sk,
	st.call_id,
	st.call_type,
	st.call_duration_seconds,
	st.data_usage_mb,
	st.call_success,
	st.revenue_naira,
	st.call_timestamp,
	c.customer_sk,
	t.tower_sk,
	n.network_type_sk,
	d.date_sk
FROM staging.teleconnect_cdr st
LEFT JOIN dim.customers c ON st.customer_id = c.customer_id
LEFT JOIN dim.tower t ON st.tower_id = t.tower_id
LEFT JOIN dim.network n ON st.network_type = n.network_type
LEFT JOIN dim.date d ON DATE(st.call_timestamp) = d.full_date
WHERE st.customer_id IS NOT NULL
limit 1000;


---adding primary key
ALTER TABLE dim.customers ADD PRIMARY KEY (customer_sk);
ALTER TABLE dim.tower ADD PRIMARY KEY (tower_sk);
ALTER TABLE dim.network ADD PRIMARY KEY (network_type_sk);
ALTER TABLE dim.date ADD PRIMARY KEY (date_sk);

ALTER TABLE dim.customers ADD UNIQUE (customer_sk);
ALTER TABLE fact.teleconnect ADD PRIMARY KEY (call_timestamp_sk);


----adding FOREIGN KEY

ALTER TABLE fact.teleconnect 
ADD CONSTRAINT FK_customer FOREIGN KEY (customer_sk) REFERENCES dim.customers(customer_sk);
ALTER TABLE fact.teleconnect 
ADD CONSTRAINT FK_tower FOREIGN KEY (tower_sk) REFERENCES dim.tower(tower_sk);
ALTER TABLE fact.teleconnect 
ADD CONSTRAINT FK_network FOREIGN KEY (network_type_sk) REFERENCES dim.network(network_type_sk);
ALTER TABLE fact.teleconnect
ADD CONSTRAINT FK_date FOREIGN KEY (date_sk) REFERENCES dim.date(date_sk);


--performance optimization on fact

CREATE INDEX idx_fact_customer ON fact.teleconnect  (customer_sk);
CREATE INDEX idx_fact_tower  ON fact.teleconnect (tower_sk);
CREATE INDEX idx_fact_network ON fact.teleconnect (network_type_sk);
CREATE INDEX idx_fact_date ON fact.teleconnect (date_sk);

--performance optimization on dimention tables
CREATE INDEX idx_customer ON dim.customers(customer_sk,customer_id);
CREATE INDEX idx_tower ON dim.tower(tower_sk);
CREATE INDEX idx_network ON dim.network(network_type_sk);
CREATE INDEX idx_date ON dim.date(date_sk);





	select * from staging.teleconnect_cdr
	select * from dim.date
	


	


 




