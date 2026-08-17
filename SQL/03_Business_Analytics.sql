/* =========================================================
   HOSPITAL EQUIPMENT ANALYTICS
   03 - BUSINESS ANALYTICS
   ========================================================= */

USE HospitalEquipmentAnalytics;
GO


/* =========================================================
   1. EQUIPMENT DISTRIBUTION BY DEVICE TYPE
   Business Question:
   What types of equipment make up the hospital inventory?
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Equipment_Count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS Inventory_Percentage
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Equipment_Count DESC;
GO


/* =========================================================
   2. MANUFACTURER INVENTORY ANALYSIS
   Business Question:
   Which manufacturers have the largest equipment inventory?
   ========================================================= */

SELECT
    Manufacturer,
    COUNT(*) AS Equipment_Count,
    COUNT(DISTINCT Device_Type) AS Device_Type_Count
FROM dbo.Medical_Device_Failure
GROUP BY Manufacturer
ORDER BY Equipment_Count DESC;
GO


/* =========================================================
   3. MAINTENANCE COST BY DEVICE TYPE
   Business Question:
   Which equipment types consume the most maintenance budget?
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Equipment_Count,
    ROUND(SUM(Maintenance_Cost), 2) AS Total_Maintenance_Cost,
    ROUND(AVG(Maintenance_Cost), 2) AS Average_Maintenance_Cost
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Total_Maintenance_Cost DESC;
GO


/* =========================================================
   4. DOWNTIME BY DEVICE TYPE
   Business Question:
   Which equipment types cause the most operational downtime?
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Equipment_Count,
    ROUND(SUM(Downtime), 2) AS Total_Downtime,
    ROUND(AVG(Downtime), 2) AS Average_Downtime
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Total_Downtime DESC;
GO


/* =========================================================
   5. FAILURE EVENTS BY DEVICE TYPE
   Business Question:
   Which equipment types experience the most failures?
   ========================================================= */

SELECT
    Device_Type,
    SUM(Failure_Event_Count) AS Total_Failure_Events,
    ROUND(AVG(Failure_Event_Count), 2) AS Average_Failure_Events,
    MAX(Failure_Event_Count) AS Maximum_Failure_Events
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Total_Failure_Events DESC;
GO


/* =========================================================
   6. MAINTENANCE FREQUENCY ANALYSIS
   Business Question:
   Which equipment types require frequent maintenance?
   ========================================================= */

SELECT
    Device_Type,
    ROUND(AVG(Maintenance_Frequency), 2) AS Average_Maintenance_Frequency,
    MAX(Maintenance_Frequency) AS Maximum_Maintenance_Frequency,
    COUNT(*) AS Equipment_Count
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Average_Maintenance_Frequency DESC;
GO


/* =========================================================
   7. EQUIPMENT AGE ANALYSIS
   Business Question:
   Which equipment categories are older?
   ========================================================= */

SELECT
    Device_Type,
    ROUND(AVG(CAST(Age AS DECIMAL(10,2))), 2) AS Average_Age,
    MIN(Age) AS Youngest_Age,
    MAX(Age) AS Oldest_Age
FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY Average_Age DESC;
GO


/* =========================================================
   8. MANUFACTURER PERFORMANCE
   Business Question:
   Which manufacturers have higher maintenance burden?
   ========================================================= */

SELECT
    Manufacturer,
    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Maintenance_Cost), 2) AS Avg_Maintenance_Cost,
    ROUND(AVG(Downtime), 2) AS Avg_Downtime,
    ROUND(AVG(CAST(Failure_Event_Count AS DECIMAL(10,2))), 2)
        AS Avg_Failure_Events
FROM dbo.Medical_Device_Failure
GROUP BY Manufacturer
ORDER BY Avg_Failure_Events DESC;
GO


/* =========================================================
   9. COUNTRY-WISE EQUIPMENT ANALYSIS
   Business Question:
   How does equipment performance vary by country?
   ========================================================= */

SELECT
    Country,
    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Maintenance_Cost), 2) AS Avg_Maintenance_Cost,
    ROUND(AVG(Downtime), 2) AS Avg_Downtime,
    ROUND(AVG(CAST(Failure_Event_Count AS DECIMAL(10,2))), 2)
        AS Avg_Failure_Events
FROM dbo.Medical_Device_Failure
GROUP BY Country
ORDER BY Equipment_Count DESC;
GO


/* =========================================================
   10. MAINTENANCE CLASS ANALYSIS
   Business Question:
   How is equipment distributed across maintenance classes?
   ========================================================= */

SELECT
    Maintenance_Class,
    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Maintenance_Cost), 2) AS Avg_Maintenance_Cost,
    ROUND(AVG(Downtime), 2) AS Avg_Downtime,
    ROUND(AVG(CAST(Failure_Event_Count AS DECIMAL(10,2))), 2)
        AS Avg_Failure_Events
FROM dbo.Medical_Device_Failure
GROUP BY Maintenance_Class
ORDER BY Maintenance_Class;
GO


/* =========================================================
   11. HIGH-COST EQUIPMENT
   Business Question:
   Which individual equipment has the highest maintenance cost?
   ========================================================= */

SELECT TOP 20
    Device_ID,
    Device_Type,
    Manufacturer,
    Model,
    Maintenance_Cost,
    Downtime,
    Failure_Event_Count
FROM dbo.Medical_Device_Failure
ORDER BY Maintenance_Cost DESC;
GO


/* =========================================================
   12. HIGH-DOWNTIME EQUIPMENT
   Business Question:
   Which equipment creates the greatest downtime burden?
   ========================================================= */

SELECT TOP 20
    Device_ID,
    Device_Type,
    Manufacturer,
    Model,
    Downtime,
    Maintenance_Cost,
    Failure_Event_Count
FROM dbo.Medical_Device_Failure
ORDER BY Downtime DESC;
GO