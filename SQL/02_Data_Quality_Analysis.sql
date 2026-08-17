/* =========================================================
   HOSPITAL EQUIPMENT ANALYTICS
   02 - DATA QUALITY & VALIDATION
   ========================================================= */

USE HospitalEquipmentAnalytics;
GO


/* =========================================================
   1. TOTAL RECORD COUNT
   Business Question:
   How many equipment records are available?
   ========================================================= */

SELECT
    COUNT(*) AS Total_Equipment
FROM dbo.Medical_Device_Failure;
GO


/* =========================================================
   2. UNIQUE DEVICE COUNT
   Business Question:
   Are all equipment IDs unique?
   ========================================================= */

SELECT
    COUNT(*) AS Total_Records,
    COUNT(DISTINCT Device_ID) AS Unique_Devices,
    COUNT(*) - COUNT(DISTINCT Device_ID) AS Duplicate_Device_Count
FROM dbo.Medical_Device_Failure;
GO


/* =========================================================
   3. DUPLICATE DEVICE IDs
   ========================================================= */

SELECT
    Device_ID,
    COUNT(*) AS Occurrence_Count
FROM dbo.Medical_Device_Failure
GROUP BY Device_ID
HAVING COUNT(*) > 1
ORDER BY Occurrence_Count DESC;
GO


/* =========================================================
   4. NEGATIVE MAINTENANCE COST CHECK
   Business Question:
   Are there any invalid negative maintenance costs?
   ========================================================= */

SELECT
    COUNT(*) AS Negative_Cost_Records
FROM dbo.Medical_Device_Failure
WHERE Maintenance_Cost < 0;
GO


/* =========================================================
   5. RECORDS CORRECTED FROM NEGATIVE COST
   ========================================================= */

SELECT
    COUNT(*) AS Corrected_Cost_Records
FROM dbo.Medical_Device_Failure
WHERE Cost_Was_Negative = 1;
GO


/* =========================================================
   6. INVALID AGE CHECK
   Business Question:
   Are there unrealistic equipment ages?
   ========================================================= */

SELECT
    COUNT(*) AS Invalid_Age_Records
FROM dbo.Medical_Device_Failure
WHERE Age < 0
   OR Age > 50;
GO


/* =========================================================
   7. INVALID DOWNTIME CHECK
   ========================================================= */

SELECT
    COUNT(*) AS Invalid_Downtime_Records
FROM dbo.Medical_Device_Failure
WHERE Downtime < 0;
GO


/* =========================================================
   8. INVALID FAILURE COUNT
   ========================================================= */

SELECT
    COUNT(*) AS Invalid_Failure_Records
FROM dbo.Medical_Device_Failure
WHERE Failure_Event_Count < 0;
GO


/* =========================================================
   9. RISK CATEGORY DISTRIBUTION
   ========================================================= */

SELECT
    Risk_Category,
    COUNT(*) AS Equipment_Count,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Percentage_of_Equipment
FROM dbo.Medical_Device_Failure
GROUP BY Risk_Category
ORDER BY Equipment_Count DESC;
GO


/* =========================================================
   10. DATA QUALITY SUMMARY
   ========================================================= */

SELECT
    COUNT(*) AS Total_Records,

    COUNT(DISTINCT Device_ID) AS Unique_Devices,

    SUM(
        CASE
            WHEN Maintenance_Cost < 0
            THEN 1 ELSE 0
        END
    ) AS Negative_Cost_Count,

    SUM(
        CASE
            WHEN Age < 0 OR Age > 50
            THEN 1 ELSE 0
        END
    ) AS Invalid_Age_Count,

    SUM(
        CASE
            WHEN Downtime < 0
            THEN 1 ELSE 0
        END
    ) AS Invalid_Downtime_Count,

    SUM(
        CASE
            WHEN Failure_Event_Count < 0
            THEN 1 ELSE 0
        END
    ) AS Invalid_Failure_Count

FROM dbo.Medical_Device_Failure;
GO