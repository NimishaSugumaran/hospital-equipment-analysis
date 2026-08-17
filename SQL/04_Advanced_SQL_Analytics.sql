/* =========================================================
   HOSPITAL EQUIPMENT ANALYTICS
   04 - ADVANCED SQL ANALYTICS
   ========================================================= */

USE HospitalEquipmentAnalytics;
GO


/* =========================================================
   1. HIGH-COST + HIGH-DOWNTIME EQUIPMENT
   Business Problem:
   Which equipment creates both financial and operational burden?
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Maintenance_Cost,
    Downtime,
    Failure_Event_Count,
    Risk_Score
FROM dbo.Medical_Device_Failure
WHERE Maintenance_Cost >
      (SELECT AVG(Maintenance_Cost)
       FROM dbo.Medical_Device_Failure)
  AND Downtime >
      (SELECT AVG(Downtime)
       FROM dbo.Medical_Device_Failure)
ORDER BY Maintenance_Cost DESC;
GO


/* =========================================================
   2. ABOVE-AVERAGE FAILURE EQUIPMENT
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Failure_Event_Count,
    Downtime,
    Maintenance_Cost
FROM dbo.Medical_Device_Failure
WHERE Failure_Event_Count >
      (SELECT AVG(CAST(Failure_Event_Count AS DECIMAL(10,2)))
       FROM dbo.Medical_Device_Failure)
ORDER BY Failure_Event_Count DESC;
GO


/* =========================================================
   3. MANUFACTURER FAILURE RANKING
   Window Function:
   RANK()
   ========================================================= */

WITH ManufacturerStats AS
(
    SELECT
        Manufacturer,
        COUNT(*) AS Equipment_Count,
        AVG(CAST(Failure_Event_Count AS DECIMAL(10,2)))
            AS Avg_Failure_Events
    FROM dbo.Medical_Device_Failure
    GROUP BY Manufacturer
)
SELECT
    Manufacturer,
    Equipment_Count,
    ROUND(Avg_Failure_Events, 2) AS Avg_Failure_Events,
    RANK() OVER (
        ORDER BY Avg_Failure_Events DESC
    ) AS Failure_Burden_Rank
FROM ManufacturerStats
ORDER BY Failure_Burden_Rank;
GO


/* =========================================================
   4. TOP 5 RISKIEST EQUIPMENT WITHIN EACH DEVICE TYPE
   Window Function:
   ROW_NUMBER()
   ========================================================= */

WITH RankedEquipment AS
(
    SELECT
        Device_ID,
        Device_Type,
        Manufacturer,
        Risk_Score,
        Risk_Category,
        Health_Score,

        ROW_NUMBER() OVER (
            PARTITION BY Device_Type
            ORDER BY Risk_Score DESC
        ) AS Risk_Rank

    FROM dbo.Medical_Device_Failure
)
SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Risk_Score,
    Risk_Category,
    Health_Score,
    Risk_Rank
FROM RankedEquipment
WHERE Risk_Rank <= 5
ORDER BY Device_Type, Risk_Rank;
GO


/* =========================================================
   5. DEVICE TYPE RISK RANKING
   ========================================================= */

WITH DeviceTypeRisk AS
(
    SELECT
        Device_Type,
        COUNT(*) AS Equipment_Count,
        AVG(Risk_Score) AS Avg_Risk_Score,
        AVG(Health_Score) AS Avg_Health_Score
    FROM dbo.Medical_Device_Failure
    GROUP BY Device_Type
)
SELECT
    Device_Type,
    Equipment_Count,
    ROUND(Avg_Risk_Score, 2) AS Avg_Risk_Score,
    ROUND(Avg_Health_Score, 2) AS Avg_Health_Score,
    DENSE_RANK() OVER (
        ORDER BY Avg_Risk_Score DESC
    ) AS Risk_Rank
FROM DeviceTypeRisk
ORDER BY Risk_Rank;
GO


/* =========================================================
   6. RUNNING MAINTENANCE COST
   Window Function:
   SUM() OVER()
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Maintenance_Cost,

    SUM(Maintenance_Cost) OVER (
        ORDER BY Maintenance_Cost DESC
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS Running_Maintenance_Cost

FROM dbo.Medical_Device_Failure
ORDER BY Maintenance_Cost DESC;
GO


/* =========================================================
   7. EQUIPMENT CONTRIBUTION TO TOTAL MAINTENANCE COST
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Maintenance_Cost,

    ROUND(
        100.0 * Maintenance_Cost /
        SUM(Maintenance_Cost) OVER (),
        4
    ) AS Cost_Contribution_Percentage

FROM dbo.Medical_Device_Failure
ORDER BY Cost_Contribution_Percentage DESC;
GO


/* =========================================================
   8. DEVICE TYPE CONTRIBUTION TO TOTAL COST
   ========================================================= */

WITH DeviceCosts AS
(
    SELECT
        Device_Type,
        SUM(Maintenance_Cost) AS Total_Cost
    FROM dbo.Medical_Device_Failure
    GROUP BY Device_Type
)
SELECT
    Device_Type,
    ROUND(Total_Cost, 2) AS Total_Maintenance_Cost,

    ROUND(
        100.0 * Total_Cost /
        SUM(Total_Cost) OVER (),
        2
    ) AS Cost_Contribution_Percentage

FROM DeviceCosts
ORDER BY Total_Maintenance_Cost DESC;
GO


/* =========================================================
   9. HIGH-RISK PERCENTAGE BY DEVICE TYPE
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Total_Equipment,

    SUM(
        CASE
            WHEN Risk_Category = 'High Risk'
            THEN 1 ELSE 0
        END
    ) AS High_Risk_Equipment,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN Risk_Category = 'High Risk'
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS High_Risk_Percentage

FROM dbo.Medical_Device_Failure
GROUP BY Device_Type
ORDER BY High_Risk_Percentage DESC;
GO


/* =========================================================
   10. RISK CATEGORY + MAINTENANCE COST ANALYSIS
   ========================================================= */

SELECT
    Risk_Category,
    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Maintenance_Cost), 2)
        AS Avg_Maintenance_Cost,
    ROUND(AVG(Downtime), 2)
        AS Avg_Downtime,
    ROUND(AVG(
        CAST(Failure_Event_Count AS DECIMAL(10,2))
    ), 2) AS Avg_Failure_Events
FROM dbo.Medical_Device_Failure
GROUP BY Risk_Category
ORDER BY
    CASE Risk_Category
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END;
GO


/* =========================================================
   11. MULTI-FACTOR HIGH PRIORITY EQUIPMENT
   Business Problem:
   Which equipment simultaneously has high risk,
   high downtime and repeated failures?
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Risk_Score,
    Risk_Category,
    Downtime,
    Failure_Event_Count,
    Maintenance_Cost,

    CASE
        WHEN Risk_Category = 'High Risk'
         AND Downtime >
             (SELECT AVG(Downtime)
              FROM dbo.Medical_Device_Failure)
         AND Failure_Event_Count >
             (SELECT AVG(
                 CAST(Failure_Event_Count AS DECIMAL(10,2))
             )
              FROM dbo.Medical_Device_Failure)
        THEN 'Critical Priority'

        WHEN Risk_Category = 'High Risk'
        THEN 'High Priority'

        WHEN Risk_Category = 'Medium Risk'
        THEN 'Monitor'

        ELSE 'Routine'
    END AS Maintenance_Priority

FROM dbo.Medical_Device_Failure
ORDER BY
    CASE
        WHEN Risk_Category = 'High Risk'
         AND Downtime >
             (SELECT AVG(Downtime)
              FROM dbo.Medical_Device_Failure)
         AND Failure_Event_Count >
             (SELECT AVG(
                 CAST(Failure_Event_Count AS DECIMAL(10,2))
             )
              FROM dbo.Medical_Device_Failure)
        THEN 1
        WHEN Risk_Category = 'High Risk'
        THEN 2
        WHEN Risk_Category = 'Medium Risk'
        THEN 3
        ELSE 4
    END,
    Risk_Score DESC;
GO


/* =========================================================
   12. MANUFACTURER BENCHMARKING
   ========================================================= */

WITH ManufacturerMetrics AS
(
    SELECT
        Manufacturer,
        COUNT(*) AS Equipment_Count,
        AVG(Maintenance_Cost) AS Avg_Cost,
        AVG(Downtime) AS Avg_Downtime,
        AVG(CAST(Failure_Event_Count AS DECIMAL(10,2)))
            AS Avg_Failures,
        AVG(Risk_Score) AS Avg_Risk
    FROM dbo.Medical_Device_Failure
    GROUP BY Manufacturer
)
SELECT
    Manufacturer,
    Equipment_Count,
    ROUND(Avg_Cost, 2) AS Avg_Cost,
    ROUND(Avg_Downtime, 2) AS Avg_Downtime,
    ROUND(Avg_Failures, 2) AS Avg_Failures,
    ROUND(Avg_Risk, 2) AS Avg_Risk,

    RANK() OVER (
        ORDER BY Avg_Risk DESC
    ) AS Risk_Rank,

    RANK() OVER (
        ORDER BY Avg_Cost DESC
    ) AS Cost_Rank

FROM ManufacturerMetrics
ORDER BY Risk_Rank;
GO


/* =========================================================
   13. AGE-BASED RISK ANALYSIS
   ========================================================= */

SELECT
    CASE
        WHEN Age <= 3 THEN '0-3 Years'
        WHEN Age <= 6 THEN '4-6 Years'
        WHEN Age <= 10 THEN '7-10 Years'
        ELSE '10+ Years'
    END AS Age_Group,

    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Risk_Score), 2) AS Avg_Risk_Score,
    ROUND(AVG(Downtime), 2) AS Avg_Downtime,
    ROUND(AVG(Maintenance_Cost), 2)
        AS Avg_Maintenance_Cost,
    ROUND(AVG(
        CAST(Failure_Event_Count AS DECIMAL(10,2))
    ), 2) AS Avg_Failure_Events

FROM dbo.Medical_Device_Failure
GROUP BY
    CASE
        WHEN Age <= 3 THEN '0-3 Years'
        WHEN Age <= 6 THEN '4-6 Years'
        WHEN Age <= 10 THEN '7-10 Years'
        ELSE '10+ Years'
    END
ORDER BY Avg_Risk_Score DESC;
GO


/* =========================================================
   14. RISK SCORE QUARTILE-STYLE SEGMENTATION
   ========================================================= */

WITH RiskBuckets AS
(
    SELECT
        Device_ID,
        Device_Type,
        Risk_Score,

        NTILE(4) OVER (
            ORDER BY Risk_Score
        ) AS Risk_Quartile

    FROM dbo.Medical_Device_Failure
)
SELECT
    Risk_Quartile,
    COUNT(*) AS Equipment_Count,
    ROUND(MIN(Risk_Score), 2) AS Min_Risk,
    ROUND(MAX(Risk_Score), 2) AS Max_Risk,
    ROUND(AVG(Risk_Score), 2) AS Avg_Risk
FROM RiskBuckets
GROUP BY Risk_Quartile
ORDER BY Risk_Quartile;
GO


/* =========================================================
   15. TOP 10% HIGHEST-RISK EQUIPMENT
   ========================================================= */

WITH RiskRanked AS
(
    SELECT
        *,
        NTILE(10) OVER (
            ORDER BY Risk_Score DESC
        ) AS Risk_Decile
    FROM dbo.Medical_Device_Failure
)
SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Risk_Score,
    Risk_Category,
    Health_Score,
    Downtime,
    Failure_Event_Count
FROM RiskRanked
WHERE Risk_Decile = 1
ORDER BY Risk_Score DESC;
GO


/* =========================================================
   16. EQUIPMENT WITH HIGH RISK BUT LOW HEALTH SCORE
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Risk_Score,
    Health_Score,
    Risk_Category
FROM dbo.Medical_Device_Failure
WHERE Risk_Score >= 60
  AND Health_Score <= 40
ORDER BY Risk_Score DESC;
GO


/* =========================================================
   17. COST EFFICIENCY ANALYSIS
   Business Problem:
   Which equipment has high maintenance cost relative
   to the number of failure events?
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Maintenance_Cost,
    Failure_Event_Count,

    ROUND(
        Maintenance_Cost /
        NULLIF(Failure_Event_Count, 0),
        2
    ) AS Cost_Per_Failure_Event

FROM dbo.Medical_Device_Failure
WHERE Failure_Event_Count > 0
ORDER BY Cost_Per_Failure_Event DESC;
GO


/* =========================================================
   18. HIGH MAINTENANCE FREQUENCY + HIGH FAILURE
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Maintenance_Frequency,
    Failure_Event_Count,
    Maintenance_Cost,
    Downtime,
    Risk_Score
FROM dbo.Medical_Device_Failure
WHERE Maintenance_Frequency >
      (SELECT AVG(
          CAST(Maintenance_Frequency AS DECIMAL(10,2))
      )
       FROM dbo.Medical_Device_Failure)
  AND Failure_Event_Count >
      (SELECT AVG(
          CAST(Failure_Event_Count AS DECIMAL(10,2))
      )
       FROM dbo.Medical_Device_Failure)
ORDER BY Risk_Score DESC;
GO


/* =========================================================
   19. COMPOSITE MAINTENANCE PRIORITY SCORE
   ========================================================= */

WITH PriorityScore AS
(
    SELECT
        Device_ID,
        Device_Type,
        Manufacturer,
        Risk_Score,
        Downtime,
        Failure_Event_Count,
        Maintenance_Cost,

        (
            (Risk_Score * 0.50)
            +
            (
                Downtime /
                NULLIF(
                    (SELECT MAX(Downtime)
                     FROM dbo.Medical_Device_Failure),
                    0
                ) * 100 * 0.25
            )
            +
            (
                Failure_Event_Count /
                NULLIF(
                    (SELECT MAX(Failure_Event_Count)
                     FROM dbo.Medical_Device_Failure),
                    0
                ) * 100 * 0.25
            )
        ) AS Composite_Priority_Score

    FROM dbo.Medical_Device_Failure
)
SELECT TOP 50
    Device_ID,
    Device_Type,
    Manufacturer,
    ROUND(Risk_Score, 2) AS Risk_Score,
    ROUND(Downtime, 2) AS Downtime,
    Failure_Event_Count,
    ROUND(Maintenance_Cost, 2) AS Maintenance_Cost,
    ROUND(Composite_Priority_Score, 2)
        AS Composite_Priority_Score,

    CASE
        WHEN Composite_Priority_Score >= 70
            THEN 'Critical'
        WHEN Composite_Priority_Score >= 50
            THEN 'High'
        WHEN Composite_Priority_Score >= 30
            THEN 'Medium'
        ELSE 'Low'
    END AS Priority_Level

FROM PriorityScore
ORDER BY Composite_Priority_Score DESC;
GO