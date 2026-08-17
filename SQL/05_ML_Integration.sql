/* =========================================================
   HOSPITAL EQUIPMENT ANALYTICS
   05 - MACHINE LEARNING INTEGRATION
   ========================================================= */

USE HospitalEquipmentAnalytics;
GO


/* =========================================================
   1. ML PREDICTION OVERVIEW
   ========================================================= */

SELECT
    Predicted_Status,
    COUNT(*) AS Equipment_Count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS Prediction_Percentage
FROM dbo.ML_Predictions
GROUP BY Predicted_Status
ORDER BY
    CASE Predicted_Status
        WHEN 'Failure' THEN 1
        WHEN 'Risk to Failure' THEN 2
        WHEN 'Normal' THEN 3
        ELSE 4
    END;
GO


/* =========================================================
   2. ML PREDICTION RISK SEGMENTATION
   ========================================================= */

SELECT
    Predicted_Status,
    COUNT(*) AS Equipment_Count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS Percentage_of_Equipment,
    ROUND(AVG(Failure_Probability), 2) AS Avg_Failure_Probability,
    ROUND(AVG(Prediction_Confidence), 2) AS Avg_Prediction_Confidence
FROM dbo.ML_Predictions
GROUP BY Predicted_Status
ORDER BY
    CASE Predicted_Status
        WHEN 'Failure' THEN 1
        WHEN 'Risk to Failure' THEN 2
        WHEN 'Normal' THEN 3
        ELSE 4
    END;
GO


/* =========================================================
   3. HIGH FAILURE PROBABILITY EQUIPMENT
   ========================================================= */

SELECT TOP 25
    Device_ID, Device_Type, Manufacturer, Model,
    Predicted_Status, Failure_Probability, Prediction_Confidence, Recommended_Action
FROM dbo.ML_Predictions
ORDER BY Failure_Probability DESC;
GO


/* =========================================================
   4. HIGH-CONFIDENCE FAILURE PREDICTIONS
   ========================================================= */

SELECT
    Device_ID, Device_Type, Manufacturer, Model,
    Predicted_Status, Failure_Probability, Prediction_Confidence, Recommended_Action
FROM dbo.ML_Predictions
WHERE Predicted_Status = 'Failure'
  AND Prediction_Confidence >= 80
ORDER BY Failure_Probability DESC, Prediction_Confidence DESC;
GO


/* =========================================================
   5. PREDICTED FAILURE BY DEVICE TYPE
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Total_Equipment,
    SUM(CASE WHEN Predicted_Status = 'Failure' THEN 1 ELSE 0 END) AS Predicted_Failures,
    SUM(CASE WHEN Predicted_Status = 'Risk to Failure' THEN 1 ELSE 0 END) AS Risk_to_Failure_Count,
    ROUND(100.0 * SUM(CASE WHEN Predicted_Status IN ('Failure', 'Risk to Failure') THEN 1 ELSE 0 END) / COUNT(*), 2) AS At_Risk_Percentage,
    ROUND(AVG(Failure_Probability), 2) AS Avg_Failure_Probability
FROM dbo.ML_Predictions
GROUP BY Device_Type
ORDER BY At_Risk_Percentage DESC;
GO


/* =========================================================
   6. ML PREDICTION + OPERATIONAL RISK
   ========================================================= */

SELECT
    e.Device_ID, e.Device_Type, e.Manufacturer, e.Model,
    e.Risk_Score, e.Risk_Category, e.Health_Score, e.Downtime, e.Failure_Event_Count,
    m.Predicted_Status, m.Failure_Probability, m.Prediction_Confidence, m.Recommended_Action
FROM dbo.Medical_Device_Failure AS e
INNER JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID
WHERE e.Risk_Category = 'High Risk'
  AND m.Predicted_Status = 'Failure'
ORDER BY m.Failure_Probability DESC, e.Risk_Score DESC;
GO


/* =========================================================
   7. CRITICAL PREDICTIVE MAINTENANCE LIST
   Business Question:
   Which equipment requires immediate intervention?

   NOTE (fixed 2026-08-11): this used to duplicate the priority
   CASE logic inline, and that copy did not match
   dbo.vw_Maintenance_Priority (missing the Risk_Score >= 40 gate
   on the Medium tier). Now just reads from the view so there is
   ONE source of truth for priority logic.
   ========================================================= */

SELECT
    Device_ID,
    Device_Type,
    Manufacturer,
    Model,
    Risk_Score,
    Risk_Category,
    Health_Score,
    Downtime,
    Failure_Event_Count,
    Maintenance_Cost,
    Predicted_Status,
    Failure_Probability,
    Prediction_Confidence,
    Recommended_Action,
    Maintenance_Priority,
    Maintenance_Priority_Score
FROM dbo.vw_Maintenance_Priority
ORDER BY
    Maintenance_Priority_Score DESC,
    Failure_Probability DESC,
    Risk_Score DESC;
GO


/* =========================================================
   8. ACTUAL FAILURE HISTORY VS ML PREDICTION
   ========================================================= */

SELECT TOP 50
    e.Device_ID, e.Device_Type, e.Manufacturer,
    e.Failure_Event_Count, e.Downtime, e.Risk_Score,
    m.Predicted_Status, m.Failure_Probability, m.Prediction_Confidence
FROM dbo.Medical_Device_Failure AS e
INNER JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID
ORDER BY m.Failure_Probability DESC, e.Failure_Event_Count DESC;
GO


/* =========================================================
   9. RECOMMENDED ACTION ANALYSIS
   ========================================================= */

SELECT
    Recommended_Action,
    COUNT(*) AS Equipment_Count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS Action_Percentage,
    ROUND(AVG(Failure_Probability), 2) AS Avg_Failure_Probability
FROM dbo.ML_Predictions
GROUP BY Recommended_Action
ORDER BY Equipment_Count DESC;
GO


/* =========================================================
   10. ML CONFIDENCE ANALYSIS
   ========================================================= */

SELECT
    CASE
        WHEN Prediction_Confidence >= 90 THEN 'Very High Confidence'
        WHEN Prediction_Confidence >= 75 THEN 'High Confidence'
        WHEN Prediction_Confidence >= 60 THEN 'Moderate Confidence'
        ELSE 'Low Confidence'
    END AS Confidence_Level,
    COUNT(*) AS Equipment_Count,
    ROUND(AVG(Prediction_Confidence), 2) AS Avg_Confidence,
    ROUND(AVG(Failure_Probability), 2) AS Avg_Failure_Probability
FROM dbo.ML_Predictions
GROUP BY
    CASE
        WHEN Prediction_Confidence >= 90 THEN 'Very High Confidence'
        WHEN Prediction_Confidence >= 75 THEN 'High Confidence'
        WHEN Prediction_Confidence >= 60 THEN 'Moderate Confidence'
        ELSE 'Low Confidence'
    END
ORDER BY Avg_Confidence DESC;
GO


/* =========================================================
   11. DEVICE TYPE ML PERFORMANCE
   ========================================================= */

SELECT
    Device_Type,
    COUNT(*) AS Total_Equipment,
    SUM(CASE WHEN Predicted_Status = 'Failure' THEN 1 ELSE 0 END) AS Failure_Count,
    SUM(CASE WHEN Predicted_Status = 'Risk to Failure' THEN 1 ELSE 0 END) AS Risk_to_Failure_Count,
    SUM(CASE WHEN Predicted_Status = 'Normal' THEN 1 ELSE 0 END) AS Normal_Count,
    ROUND(100.0 * SUM(CASE WHEN Predicted_Status IN ('Failure', 'Risk to Failure') THEN 1 ELSE 0 END) / COUNT(*), 2) AS Predictive_Risk_Percentage,
    ROUND(AVG(Failure_Probability), 2) AS Avg_Failure_Probability
FROM dbo.ML_Predictions
GROUP BY Device_Type
ORDER BY Predictive_Risk_Percentage DESC;
GO


/* =========================================================
   12. EXECUTIVE ML KPI
   ========================================================= */

SELECT
    COUNT(*) AS Total_Equipment,
    SUM(CASE WHEN Predicted_Status = 'Normal' THEN 1 ELSE 0 END) AS Normal_Equipment,
    SUM(CASE WHEN Predicted_Status = 'Risk to Failure' THEN 1 ELSE 0 END) AS Risk_to_Failure_Equipment,
    SUM(CASE WHEN Predicted_Status = 'Failure' THEN 1 ELSE 0 END) AS Predicted_Failure_Equipment,
    SUM(CASE WHEN Predicted_Status IN ('Failure', 'Risk to Failure') THEN 1 ELSE 0 END) AS Total_At_Risk_Equipment,
    ROUND(100.0 * SUM(CASE WHEN Predicted_Status IN ('Failure', 'Risk to Failure') THEN 1 ELSE 0 END) / COUNT(*), 2) AS Total_At_Risk_Percentage,
    ROUND(AVG(Failure_Probability), 2) AS Average_Failure_Probability,
    ROUND(AVG(Prediction_Confidence), 2) AS Average_Prediction_Confidence
FROM dbo.ML_Predictions;
GO


/* =========================================================
   13. TOP PRIORITY EQUIPMENT
   ========================================================= */

SELECT TOP 50
    e.Device_ID, e.Device_Type, e.Manufacturer, e.Model,
    e.Risk_Score, e.Risk_Category, e.Health_Score,
    m.Predicted_Status, m.Failure_Probability, m.Prediction_Confidence, m.Recommended_Action,
    CASE
        WHEN m.Predicted_Status = 'Failure' AND m.Failure_Probability >= 80 AND e.Risk_Score >= 70 THEN 100
        WHEN m.Predicted_Status = 'Failure' AND m.Failure_Probability >= 70 AND e.Risk_Score >= 60 THEN 90
        WHEN m.Predicted_Status = 'Risk to Failure' AND m.Failure_Probability >= 70 AND e.Risk_Score >= 60 THEN 80
        WHEN m.Predicted_Status = 'Risk to Failure' THEN 60
        ELSE 30
    END AS Maintenance_Priority_Score
FROM dbo.Medical_Device_Failure AS e
INNER JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID
ORDER BY Maintenance_Priority_Score DESC, m.Failure_Probability DESC, e.Risk_Score DESC;
GO


/* =========================================================
   14. FINAL ML + EQUIPMENT ANALYTICS DATASET
   ========================================================= */

SELECT
    e.Device_ID, e.Device_Type, e.Manufacturer, e.Model,
    e.Age, e.Maintenance_Frequency, e.Maintenance_Cost, e.Downtime, e.Failure_Event_Count,
    e.Risk_Score, e.Risk_Category, e.Health_Score,
    m.Predicted_Status, m.Failure_Probability, m.Normal_Probability, m.Risk_to_Failure_Probability,
    m.Prediction_Confidence, m.Recommended_Action
FROM dbo.Medical_Device_Failure AS e
LEFT JOIN dbo.ML_Predictions AS m
    ON e.Device_ID = m.Device_ID;
GO


/* =========================================================
   ML INTEGRATION COMPLETED
   ========================================================= */