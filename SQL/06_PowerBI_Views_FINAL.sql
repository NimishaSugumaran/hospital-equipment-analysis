

USE [HospitalEquipmentAnalytics]
GO



/* =========================================================
   01_vw_Executive_KPI_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_Executive_KPI]    Script Date: 17-08-2026 11:20:18 ******/




/* =========================================================
   1. EXECUTIVE KPI VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_Executive_KPI]
AS
SELECT
    COUNT(*) AS Total_Equipment,

    SUM(
        CASE
            WHEN Risk_Category = 'Low Risk'
            THEN 1 ELSE 0
        END
    ) AS Low_Risk_Equipment,

    SUM(
        CASE
            WHEN Risk_Category = 'Medium Risk'
            THEN 1 ELSE 0
        END
    ) AS Medium_Risk_Equipment,

    SUM(
        CASE
            WHEN Risk_Category = 'High Risk'
            THEN 1 ELSE 0
        END
    ) AS High_Risk_Equipment,

    ROUND(AVG(Risk_Score), 2) AS Average_Risk_Score,

    ROUND(AVG(Health_Score), 2) AS Average_Health_Score,

    ROUND(SUM(Maintenance_Cost), 2) AS Total_Maintenance_Cost,

    ROUND(AVG(Maintenance_Cost), 2) AS Average_Maintenance_Cost,

    ROUND(SUM(Downtime), 2) AS Total_Downtime,

    ROUND(AVG(Downtime), 2) AS Average_Downtime,

    SUM(Failure_Event_Count) AS Total_Failure_Events

FROM dbo.Medical_Device_Failure;
GO


/* =========================================================
   02_vw_Equipment_Risk_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_Equipment_Risk]    Script Date: 17-08-2026 11:14:38 ******/




/* =========================================================
   2. EQUIPMENT RISK VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_Equipment_Risk]
AS
SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Model,
    Age,
    Maintenance_Frequency,
    Maintenance_Cost,
    Downtime,
    Failure_Event_Count,
    Risk_Score,
    Risk_Category,
    Health_Score,

    CASE
        WHEN Risk_Score >= 48.03
            THEN 'High'

        WHEN Risk_Score >= 27.06
            THEN 'Medium'

        ELSE 'Low'
    END AS Risk_Priority

FROM dbo.Medical_Device_Failure;
GO


/* =========================================================
   03_vw_ML_Predictions_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_ML_Predictions]    Script Date: 17-08-2026 11:23:05 ******/




/* =========================================================
   3. ML PREDICTION VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_ML_Predictions]
AS
SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Model,

    Predicted_Status,

    Failure_Probability,
    Normal_Probability,
    Risk_to_Failure_Probability,

    Prediction_Confidence,

    Recommended_Action,

    CASE
        WHEN Predicted_Status = 'Failure'
            THEN 'Immediate Attention'

        WHEN Predicted_Status = 'Risk to Failure'
            THEN 'Preventive Maintenance'

        WHEN Predicted_Status = 'Normal'
            THEN 'Routine Monitoring'

        ELSE 'Review'
    END AS ML_Action_Priority

FROM dbo.ML_Predictions;
GO


/* =========================================================
   04_vw_Equipment_ML_Analytics_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_Equipment_ML_Analytics]    Script Date: 17-08-2026 11:19:43 ******/




/* =========================================================
   4. EQUIPMENT + ML INTEGRATED VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_Equipment_ML_Analytics]
AS
SELECT

    e.Device_ID,
    e.Device_Type,
    e.Manufacturer,
    e.Model,

    e.Age,
    e.Maintenance_Frequency,
    e.Maintenance_Cost,
    e.Downtime,
    e.Failure_Event_Count,

    e.Risk_Score,
    e.Risk_Category,
    e.Health_Score,

    m.Predicted_Status,
    m.Failure_Probability,
    m.Normal_Probability,
    m.Risk_to_Failure_Probability,
    m.Prediction_Confidence,
    m.Recommended_Action,

    CASE

        WHEN e.Risk_Score >= 70
         AND m.Predicted_Status = 'Failure'
         AND m.Failure_Probability >= 80
        THEN 'Critical'

        WHEN e.Risk_Score >= 60
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
        THEN 'High'

        WHEN e.Risk_Score >= 40
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
        THEN 'Medium'

        ELSE 'Low'

    END AS Maintenance_Priority

FROM dbo.Medical_Device_Failure AS e

LEFT JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID;
GO


/* =========================================================
   05_vw_DeviceType_Performance_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_DeviceType_Performance]    Script Date: 17-08-2026 11:16:10 ******/




/* =========================================================
   5. DEVICE TYPE PERFORMANCE VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_DeviceType_Performance]
AS
SELECT
    e.Device_Type,

    COUNT(*) AS Total_Equipment,

    ROUND(AVG(e.Age), 2) AS Average_Age,

    ROUND(
        AVG(e.Maintenance_Cost),
        2
    ) AS Average_Maintenance_Cost,

    ROUND(
        SUM(e.Maintenance_Cost),
        2
    ) AS Total_Maintenance_Cost,

    ROUND(
        AVG(e.Downtime),
        2
    ) AS Average_Downtime,

    ROUND(
        SUM(e.Downtime),
        2
    ) AS Total_Downtime,

    SUM(e.Failure_Event_Count)
        AS Total_Failure_Events,

    ROUND(
        AVG(e.Risk_Score),
        2
    ) AS Average_Risk_Score,

    ROUND(
        AVG(e.Health_Score),
        2
    ) AS Average_Health_Score,

    SUM(
        CASE
            WHEN e.Risk_Category = 'High Risk'
            THEN 1 ELSE 0
        END
    ) AS High_Risk_Equipment,

    SUM(
        CASE
            WHEN m.Predicted_Status = 'Failure'
            THEN 1 ELSE 0
        END
    ) AS Predicted_Failures,

    SUM(
        CASE
            WHEN m.Predicted_Status = 'Risk to Failure'
            THEN 1 ELSE 0
        END
    ) AS Risk_to_Failure_Equipment,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN m.Predicted_Status IN
                    ('Failure', 'Risk to Failure')
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS Predictive_Risk_Percentage

FROM dbo.Medical_Device_Failure AS e

LEFT JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID

GROUP BY
    e.Device_Type;
GO


/* =========================================================
   06_vw_Manufacturer_Performance_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_Manufacturer_Performance]    Script Date: 17-08-2026 11:21:31 ******/




/* =========================================================
   6. MANUFACTURER PERFORMANCE VIEW
      FINAL CORRECTED VERSION
      GRAIN = Device_Type + Manufacturer
   ========================================================= */

ALTER   VIEW [dbo].[vw_Manufacturer_Performance]
AS
SELECT
    e.Device_Type,
    e.Manufacturer,

    COUNT(*) AS Total_Equipment,

    ROUND(
        SUM(e.Maintenance_Cost),
        2
    ) AS Total_Maintenance_Cost,

    ROUND(
        AVG(e.Maintenance_Cost),
        2
    ) AS Average_Maintenance_Cost,

    ROUND(
        SUM(e.Downtime),
        2
    ) AS Total_Downtime,

    ROUND(
        AVG(e.Downtime),
        2
    ) AS Average_Downtime,

    SUM(e.Failure_Event_Count)
        AS Total_Failure_Events,

    ROUND(
        AVG(
            CAST(
                e.Failure_Event_Count
                AS DECIMAL(10,2)
            )
        ),
        2
    ) AS Average_Failure_Events,

    ROUND(
        AVG(e.Risk_Score),
        2
    ) AS Average_Risk_Score,

    ROUND(
        AVG(e.Health_Score),
        2
    ) AS Average_Health_Score,

    SUM(
        CASE
            WHEN e.Risk_Category = 'High Risk'
            THEN 1 ELSE 0
        END
    ) AS High_Risk_Equipment,

    SUM(
        CASE
            WHEN e.Risk_Category = 'Medium Risk'
            THEN 1 ELSE 0
        END
    ) AS Medium_Risk_Equipment,

    SUM(
        CASE
            WHEN e.Risk_Category = 'Low Risk'
            THEN 1 ELSE 0
        END
    ) AS Low_Risk_Equipment,

    SUM(
        CASE
            WHEN m.Predicted_Status = 'Normal'
            THEN 1 ELSE 0
        END
    ) AS Normal_Equipment,

    SUM(
        CASE
            WHEN m.Predicted_Status = 'Risk to Failure'
            THEN 1 ELSE 0
        END
    ) AS Risk_to_Failure_Equipment,

    SUM(
        CASE
            WHEN m.Predicted_Status = 'Failure'
            THEN 1 ELSE 0
        END
    ) AS Predicted_Failures,

    COUNT(DISTINCT e.Device_Type)
        AS Device_Type_Count

FROM dbo.Medical_Device_Failure AS e

LEFT JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID

GROUP BY
    e.Device_Type,
    e.Manufacturer;
GO


/* =========================================================
   07_vw_Maintenance_Priority_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_Maintenance_Priority]    Script Date: 17-08-2026 11:20:57 ******/




/* =========================================================
   7. MAINTENANCE PRIORITY VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_Maintenance_Priority]
AS
SELECT TOP 100 PERCENT

    e.Device_ID,
    e.Device_Type,
    e.Manufacturer,
    e.Model,

    e.Age,
    e.Maintenance_Cost,
    e.Downtime,
    e.Failure_Event_Count,

    e.Risk_Score,
    e.Risk_Category,
    e.Health_Score,

    m.Predicted_Status,
    m.Failure_Probability,
    m.Prediction_Confidence,
    m.Recommended_Action,

    CASE

        WHEN e.Risk_Score >= 70
         AND m.Predicted_Status = 'Failure'
         AND m.Failure_Probability >= 80
        THEN 'Critical'

        WHEN e.Risk_Score >= 60
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
         AND m.Failure_Probability >= 70
        THEN 'High'

        WHEN e.Risk_Score >= 40
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
        THEN 'Medium'

        ELSE 'Low'

    END AS Maintenance_Priority,

    CASE

        WHEN e.Risk_Score >= 70
         AND m.Predicted_Status = 'Failure'
         AND m.Failure_Probability >= 80
        THEN 100

        WHEN e.Risk_Score >= 60
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
         AND m.Failure_Probability >= 70
        THEN 80

        WHEN e.Risk_Score >= 40
         AND m.Predicted_Status IN
             ('Failure', 'Risk to Failure')
        THEN 60

        ELSE 30

    END AS Maintenance_Priority_Score

FROM dbo.Medical_Device_Failure AS e

LEFT JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID

ORDER BY
    Maintenance_Priority_Score DESC;
GO


/* =========================================================
   08_vw_ML_Status_Summary_FINAL.sql
   ========================================================= */

/****** Object:  View [dbo].[vw_ML_Status_Summary]    Script Date: 17-08-2026 11:23:41 ******/




/* =========================================================
   8. ML STATUS SUMMARY VIEW
   ========================================================= */

ALTER   VIEW [dbo].[vw_ML_Status_Summary]
AS
SELECT
    Predicted_Status,

    COUNT(*) AS Equipment_Count,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Percentage_of_Equipment,

    ROUND(
        AVG(Failure_Probability),
        2
    ) AS Average_Failure_Probability,

    ROUND(
        AVG(Prediction_Confidence),
        2
    ) AS Average_Prediction_Confidence

FROM dbo.ML_Predictions

GROUP BY
    Predicted_Status;
GO
