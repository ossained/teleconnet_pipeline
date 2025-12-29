


--- Adding security access
-- =========================
-- 1. Create Roles
-- =========================
CREATE ROLE teleconnect_financeteam;
CREATE ROLE teleconnect_networkingteam;

-- =========================
-- 2. Create Users
-- =========================
CREATE USER financeteam WITH PASSWORD 'connect';
CREATE USER networkingteam WITH PASSWORD 'connect';

-- =========================
-- 3. Assign Roles to Users
-- =========================
GRANT teleconnect_financeteam TO financeteam;
GRANT teleconnect_networkingteam TO networkingteam;

-- =========================
-- 4. Finance Team Permissions
-- =========================
-- Schema access
GRANT USAGE ON SCHEMA fact TO teleconnect_financeteam;
GRANT USAGE ON SCHEMA dim TO teleconnect_financeteam;

-- Table access
GRANT SELECT ON fact.teleconnect TO teleconnect_financeteam;
GRANT SELECT ON dim.customers TO teleconnect_financeteam;

-- =========================
-- 5. Networking Team Permissions
-- =========================
-- Schema access
GRANT USAGE ON SCHEMA fact TO teleconnect_networkingteam;
GRANT USAGE ON SCHEMA dim TO teleconnect_networkingteam;

-- Table access
GRANT SELECT ON fact.teleconnect TO teleconnect_networkingteam;
GRANT SELECT ON dim.network TO teleconnect_networkingteam;
GRANT SELECT ON dim.tower TO teleconnect_networkingteam;