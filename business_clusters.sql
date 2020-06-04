
-- Link active businesses to registered businesses table
-- Note: Before this, upload the registered businesses
-- spatial dataset to Postgres through your preferred method
-- (I used a Postgres connection in QGIS)

CREATE TABLE sf_businesses AS (
	SELECT DISTINCT r.dba_name AS bus_name 
	, r.certificat AS bus_id
	, r.lic AS lic_code
	, r.lic_code_d AS lic_name
	, r.naic_code AS naic_code
	, r.naic_code_ AS naic_name
	, CASE WHEN "Business Account Number" IS NOT NULL 
		THEN 1 ELSE 0 END AS active
	, ST_Transform(geom, 32611) AS geom 
	FROM sf_registered_businesses r 
	LEFT JOIN sf_active_businesses a 
		ON a."Business Account Number" = r.certificat
);

-- Create a table of the features you'd like to cluster. 
-- For this example, I'm selecting food resources based on 
-- the categories outlined in the metadata.

CREATE TABLE sf_food AS (
	SELECT DISTINCT bus_name
	, bus_id 
	, lic_code
	, lic_name
	, naic_code
	, naic_name
	, active
	, geom
    FROM sf_businesses
    WHERE 1=1
    	AND active = 1
    	AND (
    		LOWER(lic_name) LIKE '%food%'
    		OR LOWER(lic_name) LIKE '%produce stand%'
    		OR LOWER(lic_name) LIKE '%certified farmers markets%'
    		OR LOWER(lic_name) LIKE '%restaurant%'
    		OR LOWER(lic_name) LIKE '%take-out establishment%'
    		OR LOWER(lic_name) LIKE '%supermarkets%'
    	)
    	AND LOWER(lic_name) NOT LIKE '%mobile food prp unit%'
    	AND LOWER(lic_name) NOT LIKE '%caterer retail food vehicles%'
    	AND LOWER(lic_name) NOT LIKE '%school%'
);

-- Run the ST_ClusterDBSCAN function to create
-- clusters.

CREATE TABLE clustered AS (
	SELECT bus_name
	, bus_id 
	, lic_code
	, lic_name
	, naic_code
	, naic_name
	, active
	-- Try out some different cluster parameters.
	-- Run it multiple times at different levels to
	-- get a range of cluster densities.
	, ST_ClusterDBSCAN(geom, eps := 100, minpoints := 5) 
		over () AS cid, geom
    FROM sf_food
    WHERE 1=1
);
