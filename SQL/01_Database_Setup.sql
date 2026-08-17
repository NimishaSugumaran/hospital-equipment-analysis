IF DB_ID('HospitalEquipmentAnalytics') IS NULL
BEGIN
    CREATE DATABASE HospitalEquipmentAnalytics;
END;
GO

USE HospitalEquipmentAnalytics;
GO

SELECT
    DB_NAME() AS Database_Name,
    GETDATE() AS Setup_Date;
GO