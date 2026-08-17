import pandas as pd
import matplotlib.pyplot as plt

from sklearn.model_selection import (
    train_test_split,
    StratifiedKFold,
    cross_val_predict
)

from sklearn.ensemble import RandomForestClassifier

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix,
    ConfusionMatrixDisplay,
    classification_report
)


# ============================================================
# 1. LOAD CLEANED DATASET
# ============================================================

df = pd.read_csv("../Data/Medical_Device_Failure_Cleaned.csv")

print("Cleaned Dataset Shape:", df.shape)


# ============================================================
# 2. CREATE 3-CLASS EQUIPMENT STATUS
# ============================================================
#
# 0–1  -> Normal
# 2–3  -> Risk to Failure
# 4+   -> Failure
#
# IMPORTANT:
# Original Failure_Event_Count is NOT modified.
# Only a new target column is created.
#

def equipment_status(failure_count):

    if failure_count <= 1:
        return "Normal"

    elif failure_count <= 3:
        return "Risk to Failure"

    else:
        return "Failure"


df["Equipment_Status"] = df["Failure_Event_Count"].apply(
    equipment_status
)


# ============================================================
# 3. TARGET DISTRIBUTION
# ============================================================

print("\n===================================")
print("3-CLASS TARGET DISTRIBUTION")
print("===================================")

target_counts = df["Equipment_Status"].value_counts()

print(target_counts)


print("\n--- Target Percentage ---")

target_percentage = (
    df["Equipment_Status"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)

print(target_percentage)


# ============================================================
# 4. SELECT ML FEATURES
# ============================================================
#
# Failure_Event_Count is excluded because Equipment_Status
# is derived from it.
#
# Risk_Score is excluded because it uses Failure_Event_Count.
#
# Health_Score is also excluded because it is derived from
# the risk-related variables.
#

features = [
    "Age",
    "Maintenance_Frequency",
    "Maintenance_Cost",
    "Downtime",
    "Device_Type",
    "Manufacturer",
    "Model"
]


X = df[features].copy()

y = df["Equipment_Status"]


# ============================================================
# 5. CATEGORICAL ENCODING
# ============================================================

X_encoded = pd.get_dummies(
    X,
    columns=[
        "Device_Type",
        "Manufacturer",
        "Model"
    ],
    drop_first=True
)


print("\n===================================")
print("FEATURE INFORMATION")
print("===================================")

print("Original Feature Count:", X.shape[1])
print("Encoded Feature Count:", X_encoded.shape[1])


# ============================================================
# 6. TRAIN / TEST SPLIT
# ============================================================

X_train, X_test, y_train, y_test = train_test_split(
    X_encoded,
    y,
    test_size=0.20,
    random_state=42,
    stratify=y
)


print("\n===================================")
print("TRAIN / TEST SPLIT")
print("===================================")

print("Training records:", len(X_train))
print("Testing records:", len(X_test))


# ============================================================
# 7. RANDOM FOREST MODEL
# ============================================================

model = RandomForestClassifier(
    n_estimators=300,
    random_state=42,
    class_weight="balanced",
    n_jobs=-1
)


# ============================================================
# 8. TRAIN MODEL
# ============================================================

print("\n===================================")
print("TRAINING RANDOM FOREST")
print("===================================")

model.fit(
    X_train,
    y_train
)

print("Random Forest Training Completed.")


# ============================================================
# 9. TEST DATA PREDICTION
# ============================================================

y_pred = model.predict(X_test)


# ============================================================
# 10. MODEL EVALUATION
# ============================================================

accuracy = accuracy_score(
    y_test,
    y_pred
)

precision = precision_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)

recall = recall_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)

f1 = f1_score(
    y_test,
    y_pred,
    average="weighted",
    zero_division=0
)


print("\n===================================")
print("3-CLASS RANDOM FOREST RESULTS")
print("===================================")

print("Accuracy :", round(accuracy, 4))
print("Precision:", round(precision, 4))
print("Recall   :", round(recall, 4))
print("F1 Score :", round(f1, 4))


# ============================================================
# 11. CLASSIFICATION REPORT
# ============================================================

print("\n===================================")
print("CLASSIFICATION REPORT")
print("===================================")

labels = [
    "Normal",
    "Risk to Failure",
    "Failure"
]

print(
    classification_report(
        y_test,
        y_pred,
        labels=labels,
        zero_division=0
    )
)


# ============================================================
# 12. CONFUSION MATRIX
# ============================================================

cm = confusion_matrix(
    y_test,
    y_pred,
    labels=labels
)


print("\n===================================")
print("CONFUSION MATRIX")
print("===================================")

print(cm)


# ============================================================
# 13. CONFUSION MATRIX VISUALIZATION
# ============================================================

disp = ConfusionMatrixDisplay(
    confusion_matrix=cm,
    display_labels=labels
)

disp.plot(
    xticks_rotation=30
)

plt.title(
    "Random Forest - Equipment Status Confusion Matrix"
)

plt.tight_layout()

plt.show()


# ============================================================
# 14. FEATURE IMPORTANCE
# ============================================================

feature_importance = pd.Series(
    model.feature_importances_,
    index=X_encoded.columns
).sort_values(
    ascending=False
)


print("\n===================================")
print("TOP 10 IMPORTANT FEATURES")
print("===================================")

print(
    feature_importance.head(10)
)


# ============================================================
# 15. FEATURE IMPORTANCE CHART
# ============================================================

plt.figure(figsize=(10, 6))

feature_importance.head(10).sort_values().plot(
    kind="barh"
)

plt.title(
    "Top 10 Features - Random Forest Feature Importance"
)

plt.xlabel("Importance")

plt.tight_layout()

plt.show()


# ============================================================
# 16. OUT-OF-FOLD PREDICTION
# ============================================================

print("\n===================================")
print("CREATING OUT-OF-SAMPLE PREDICTIONS")
print("===================================")

cv = StratifiedKFold(
    n_splits=5,
    shuffle=True,
    random_state=42
)


oof_prediction = cross_val_predict(
    model,
    X_encoded,
    y,
    cv=cv,
    method="predict",
    n_jobs=-1
)


oof_probability = cross_val_predict(
    model,
    X_encoded,
    y,
    cv=cv,
    method="predict_proba",
    n_jobs=-1
)


print("Out-of-sample predictions completed.")


# ============================================================
# 17. CREATE FINAL PREDICTION DATASET
# ============================================================

prediction_df = df[
    [
        "Device_ID",
        "Device_Type",
        "Manufacturer",
        "Model",
        "Age",
        "Maintenance_Frequency",
        "Maintenance_Cost",
        "Downtime",
        "Failure_Event_Count",
        "Risk_Score",
        "Risk_Category",
        "Equipment_Status"
    ]
].copy()


prediction_df["Predicted_Status"] = oof_prediction


# ============================================================
# 18. CLASS PROBABILITIES
# ============================================================

class_names = model.classes_


for i, class_name in enumerate(class_names):

    safe_name = (
        class_name
        .replace(" ", "_")
        .replace("-", "_")
    )

    prediction_df[
        f"{safe_name}_Probability"
    ] = (
        oof_probability[:, i] * 100
    ).round(2)


# ============================================================
# 19. PREDICTION CONFIDENCE
# ============================================================

prediction_df["Prediction_Confidence"] = (
    oof_probability.max(axis=1) * 100
).round(2)


# ============================================================
# 20. MAINTENANCE RECOMMENDATION
# ============================================================

def maintenance_action(status):

    if status == "Failure":

        return "Inspect Immediately"

    elif status == "Risk to Failure":

        return "Schedule Preventive Maintenance"

    else:

        return "Routine Monitoring"


prediction_df["Recommended_Action"] = (
    prediction_df["Predicted_Status"]
    .apply(maintenance_action)
)


# ============================================================
# 21. SORT BY PREDICTION CONFIDENCE
# ============================================================

prediction_df = prediction_df.sort_values(
    by="Prediction_Confidence",
    ascending=False
)


# ============================================================
# 22. TOP 20 PREDICTIONS
# ============================================================

print("\n===================================")
print("TOP 20 PREDICTED EQUIPMENT RISK")
print("===================================")

print(
    prediction_df[
        [
            "Device_ID",
            "Device_Type",
            "Predicted_Status",
            "Prediction_Confidence",
            "Recommended_Action"
        ]
    ]
    .head(20)
    .to_string(index=False)
)


# ============================================================
# 23. PREDICTION SUMMARY
# ============================================================

print("\n===================================")
print("PREDICTION SUMMARY")
print("===================================")


print("\n--- Predicted Status Count ---")

predicted_counts = (
    prediction_df["Predicted_Status"]
    .value_counts()
)

print(predicted_counts)


print("\n--- Predicted Status Percentage ---")

predicted_percentage = (
    prediction_df["Predicted_Status"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)

print(predicted_percentage)


# ============================================================
# 24. MAINTENANCE ACTION SUMMARY
# ============================================================

print("\n===================================")
print("MAINTENANCE ACTION SUMMARY")
print("===================================")

print(
    prediction_df[
        "Recommended_Action"
    ].value_counts()
)


# ============================================================
# 25. OUT-OF-FOLD MODEL VALIDATION
# ============================================================

oof_accuracy = accuracy_score(
    y,
    oof_prediction
)

oof_precision = precision_score(
    y,
    oof_prediction,
    average="weighted",
    zero_division=0
)

oof_recall = recall_score(
    y,
    oof_prediction,
    average="weighted",
    zero_division=0
)

oof_f1 = f1_score(
    y,
    oof_prediction,
    average="weighted",
    zero_division=0
)


print("\n===================================")
print("OUT-OF-FOLD MODEL VALIDATION")
print("===================================")

print("Accuracy :", round(oof_accuracy, 4))
print("Precision:", round(oof_precision, 4))
print("Recall   :", round(oof_recall, 4))
print("F1 Score :", round(oof_f1, 4))


# ============================================================
# 26. ACTUAL VS PREDICTED DISTRIBUTION
# ============================================================

actual_distribution = (
    df["Equipment_Status"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)

predicted_distribution = (
    prediction_df["Predicted_Status"]
    .value_counts(normalize=True)
    .mul(100)
    .round(2)
)


distribution_comparison = pd.DataFrame({
    "Actual_Percentage": actual_distribution,
    "Predicted_Percentage": predicted_distribution
}).fillna(0)


print("\n===================================")
print("ACTUAL VS PREDICTED DISTRIBUTION")
print("===================================")

print(
    distribution_comparison
)


# ============================================================
# 27. PREDICTION DISTRIBUTION CHART
# ============================================================

prediction_df[
    "Predicted_Status"
].value_counts().reindex(
    labels,
    fill_value=0
).plot(
    kind="bar"
)

plt.title(
    "Predicted Equipment Status Distribution"
)

plt.xlabel(
    "Equipment Status"
)

plt.ylabel(
    "Number of Equipment"
)

plt.xticks(
    rotation=20
)

plt.tight_layout()

plt.show()


# ============================================================
# 28. PREDICTION CONFIDENCE DISTRIBUTION
# ============================================================

plt.figure(figsize=(8, 5))

plt.hist(
    prediction_df["Prediction_Confidence"],
    bins=10
)

plt.title(
    "Prediction Confidence Distribution"
)

plt.xlabel(
    "Prediction Confidence (%)"
)

plt.ylabel(
    "Number of Equipment"
)

plt.tight_layout()

plt.show()


# ============================================================
# 29. FINAL DATA VALIDATION
# ============================================================

print("\n===================================")
print("FINAL POWER BI DATA CHECK")
print("===================================")

print(
    "Rows:",
    len(prediction_df)
)

print(
    "Columns:",
    len(prediction_df.columns)
)


print("\nMissing Values:")

print(
    prediction_df.isnull().sum()
)


print("\nDuplicate Device IDs:")

print(
    prediction_df["Device_ID"].duplicated().sum()
)


print("\nPredicted Status:")

print(
    prediction_df[
        "Predicted_Status"
    ].value_counts()
)


print("\nPrediction Confidence Range:")

print(
    prediction_df[
        "Prediction_Confidence"
    ].min(),
    "to",
    prediction_df[
        "Prediction_Confidence"
    ].max()
)


# ============================================================
# 30. SAVE FINAL ML PREDICTIONS
# ============================================================

prediction_df.to_csv(
    "../Data/ML_Predictions.csv",
    index=False
)


print("\n===================================")
print("FINAL ML PREDICTION FILE SAVED")
print("===================================")

print(
    "../Data/ML_Predictions.csv"
)


# ============================================================
# 31. COMPLETION MESSAGE
# ============================================================

print("\n===================================")
print("3-CLASS RANDOM FOREST ML PIPELINE")
print("COMPLETED SUCCESSFULLY")
print("===================================")