import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# 1. LOAD DATA
# ============================================================

df = pd.read_csv(
    "../Data/Medical_Device_Failure_dataset.csv"
)

print("Original Dataset Shape:", df.shape)


# ============================================================
# 2. DATA QUALITY CHECK
# ============================================================

print("\n--- Missing Values ---")

print(
    df.isnull().sum()
)


print("\n--- Duplicate Rows ---")

print(
    df.duplicated().sum()
)


# ============================================================
# 2B. DATA TYPES CHECK
# ============================================================

print("\n--- Data Types ---")

print(
    df.dtypes
)


# ============================================================
# 2C. OUTLIER CHECK - IQR METHOD
# ============================================================

print("\n--- Outlier Check (IQR method) ---")


for col in [
    "Age",
    "Downtime",
    "Maintenance_Cost"
]:

    Q1 = df[col].quantile(0.25)

    Q3 = df[col].quantile(0.75)

    IQR = Q3 - Q1

    lower = Q1 - 1.5 * IQR

    upper = Q3 + 1.5 * IQR

    outliers = df[
        (df[col] < lower) |
        (df[col] > upper)
    ]

    print(
        f"{col}: {len(outliers)} outliers "
        f"(range: {lower:.2f} to {upper:.2f})"
    )


# ============================================================
# 3. NEGATIVE MAINTENANCE COST CHECK
# ============================================================

negative_cost = df[
    df["Maintenance_Cost"] < 0
]

print("\n--- Negative Maintenance Cost ---")

print(
    "Negative cost records:",
    len(negative_cost)
)


# ============================================================
# 3B. INVESTIGATE NEGATIVE COST RECORDS
# ============================================================

print("\n--- Negative Cost Statistics ---")

print(
    negative_cost["Maintenance_Cost"].describe()
)


print("\n--- Negative Cost by Device Type ---")

print(
    negative_cost["Device_Type"].value_counts()
)


print("\n--- Negative Cost by Manufacturer ---")

print(
    negative_cost["Manufacturer"].value_counts()
)


print("\n--- Positive Maintenance Cost Statistics ---")

print(
    df[
        df["Maintenance_Cost"] >= 0
    ]["Maintenance_Cost"].describe()
)


# ============================================================
# 3C. FIX NEGATIVE MAINTENANCE COST
# ============================================================

df["Cost_Was_Negative"] = (
    df["Maintenance_Cost"] < 0
)


df["Maintenance_Cost"] = (
    df["Maintenance_Cost"].abs()
)


print("\n--- After Sign Correction ---")

print(
    "Records corrected:",
    df["Cost_Was_Negative"].sum()
)


print(
    "Remaining negative values:",
    (
        df["Maintenance_Cost"] < 0
    ).sum()
)


# ============================================================
# 4. CREATE CLEAN DATASET
# ============================================================

clean_df = df.copy()


print("\n--- Cleaning Result ---")


print(
    "Original rows:",
    len(df)
)


print(
    "Cleaned rows:",
    len(clean_df)
)


# ============================================================
# 5. FINAL DATA QUALITY CHECK
# ============================================================

print("\n--- Final Data Quality Check ---")


print("\nMissing values:")

print(
    clean_df.isnull().sum()
)


print("\nDuplicate rows:")

print(
    clean_df.duplicated().sum()
)


print("\nFinal shape:")

print(
    clean_df.shape
)


# ============================================================
# 6. CREATE AGE GROUP
# ============================================================

def age_group(age):

    if age < 3:

        return "0-2 Years"

    elif age < 6:

        return "3-5 Years"

    elif age < 9:

        return "6-8 Years"

    else:

        return "9+ Years"


clean_df["Age_Group"] = (
    clean_df["Age"].apply(age_group)
)


# ============================================================
# 7. NORMALIZATION FUNCTION
# ============================================================

def normalize(series):

    minimum = series.min()

    maximum = series.max()

    if maximum == minimum:

        return pd.Series(
            [0] * len(series),
            index=series.index
        )

    return (
        (series - minimum) /
        (maximum - minimum)
    ) * 100


# ============================================================
# 8. NORMALIZE RISK COMPONENTS
# ============================================================

clean_df["Age_Risk"] = normalize(
    clean_df["Age"]
)


clean_df["Downtime_Risk"] = normalize(
    clean_df["Downtime"]
)


clean_df["Failure_Risk"] = normalize(
    clean_df["Failure_Event_Count"]
)


clean_df["Cost_Risk"] = normalize(
    clean_df["Maintenance_Cost"]
)


# ============================================================
# 9. CALCULATE RISK SCORE
#
# Age              = 20%
# Downtime         = 30%
# Failure Events   = 30%
# Maintenance Cost = 20%
# ============================================================

clean_df["Risk_Score"] = (

    clean_df["Age_Risk"] * 0.20

    +

    clean_df["Downtime_Risk"] * 0.30

    +

    clean_df["Failure_Risk"] * 0.30

    +

    clean_df["Cost_Risk"] * 0.20

)


# ============================================================
# 9B. CALCULATE HEALTH SCORE
#
# Health Score = 100 - Risk Score
#
# Higher Health Score = Better equipment condition
# Lower Health Score  = Higher equipment risk
# ============================================================

clean_df["Health_Score"] = (
    100 - clean_df["Risk_Score"]
)


# ============================================================
# 10. RISK CATEGORY - PERCENTILE BASED
#
# Top 10%       = High Risk
# Next 30%      = Medium Risk
# Bottom 60%    = Low Risk
#
# Thresholds are calculated from the actual Risk_Score
# distribution.
# ============================================================

high_threshold = (
    clean_df["Risk_Score"]
    .quantile(0.90)
)


medium_threshold = (
    clean_df["Risk_Score"]
    .quantile(0.60)
)


def risk_category(score):

    if score >= high_threshold:

        return "High Risk"

    elif score >= medium_threshold:

        return "Medium Risk"

    else:

        return "Low Risk"


clean_df["Risk_Category"] = (
    clean_df["Risk_Score"]
    .apply(risk_category)
)


# ============================================================
# 11. RISK CATEGORY DISTRIBUTION
# ============================================================

print("\n")
print("============================================================")
print("RISK CATEGORY DISTRIBUTION")
print("============================================================")


risk_counts = (
    clean_df["Risk_Category"]
    .value_counts()
    .reindex(
        [
            "Low Risk",
            "Medium Risk",
            "High Risk"
        ],
        fill_value=0
    )
)


print("\nCounts:")

print(
    risk_counts
)


risk_percent = (
    clean_df["Risk_Category"]
    .value_counts(
        normalize=True
    )
    .mul(100)
    .reindex(
        [
            "Low Risk",
            "Medium Risk",
            "High Risk"
        ],
        fill_value=0
    )
    .round(2)
)


print("\nPercentages:")

print(
    risk_percent
)


# ============================================================
# 12. PRINT RISK THRESHOLDS
# ============================================================

print("\n")
print("============================================================")
print("RISK THRESHOLDS")
print("============================================================")


print(
    "High Risk >= ",
    round(high_threshold, 2)
)


print(
    "Medium Risk >= ",
    round(medium_threshold, 2)
)


print(
    "Low Risk < ",
    round(medium_threshold, 2)
)


# ============================================================
# 13. RISK SCORE SUMMARY
# ============================================================

print("\n")
print("============================================================")
print("RISK SCORE SUMMARY")
print("============================================================")


print(
    clean_df["Risk_Score"].describe()
)


# ============================================================
# 14. HEALTH SCORE SUMMARY
# ============================================================

print("\n")
print("============================================================")
print("HEALTH SCORE SUMMARY")
print("============================================================")


print(
    clean_df["Health_Score"].describe()
)


# ============================================================
# 15. TOP 10 HIGHEST-RISK DEVICES
# ============================================================

print("\n")
print("============================================================")
print("TOP 10 HIGHEST-RISK DEVICES")
print("============================================================")


top_risk = (
    clean_df[
        [
            "Device_ID",
            "Device_Type",
            "Manufacturer",
            "Model",
            "Risk_Score",
            "Health_Score",
            "Risk_Category"
        ]
    ]
    .sort_values(
        "Risk_Score",
        ascending=False
    )
    .head(10)
)


print(
    top_risk.to_string(
        index=False
    )
)


# ============================================================
# 16. SAVE CLEANED DATASET
# ============================================================

output_path = (
    "../Data/Medical_Device_Failure_Cleaned.csv"
)


clean_df.to_csv(
    output_path,
    index=False
)


print("\n")
print("============================================================")
print("CLEANED DATASET SAVED")
print("============================================================")


print(
    "Output:",
    output_path
)


print(
    "Rows:",
    len(clean_df)
)


print(
    "Columns:",
    len(clean_df.columns)
)


# ============================================================
# 17. FINAL COLUMN CHECK
# ============================================================

print("\n")
print("============================================================")
print("FINAL COLUMNS")
print("============================================================")


print(
    clean_df.columns.tolist()
)


# ============================================================
# 18. FINAL RISK CATEGORY CHECK
# ============================================================

print("\n")
print("============================================================")
print("FINAL RISK CATEGORY CHECK")
print("============================================================")


print(
    clean_df["Risk_Category"]
    .value_counts()
)


print("\nRisk Category %:")


print(
    clean_df["Risk_Category"]
    .value_counts(
        normalize=True
    )
    .mul(100)
    .round(2)
)


# ============================================================
# 19. FINAL HEALTH SCORE CHECK
# ============================================================

print("\n")
print("============================================================")
print("FINAL HEALTH SCORE CHECK")
print("============================================================")


print(
    "Health_Score column present:",
    "Health_Score" in clean_df.columns
)


print(
    "Health Score formula: 100 - Risk_Score"
)


print(
    "Health Score range:",
    round(clean_df["Health_Score"].min(), 2),
    "to",
    round(clean_df["Health_Score"].max(), 2)
)


# ============================================================
# 20. COMPLETION MESSAGE
# ============================================================

print("\n")
print("============================================================")
print("DATA CLEANING COMPLETED SUCCESSFULLY")
print("============================================================")


print(
    "Risk Score calculation: COMPLETED"
)


print(
    "Health Score calculation: COMPLETED"
)


print(
    "Percentile Risk Category: COMPLETED"
)


print(
    "Negative Cost Correction: COMPLETED"
)


print(
    "Cleaned CSV: SAVED"
)


print(
    "Next step: ML pipeline"
)