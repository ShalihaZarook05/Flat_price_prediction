import pandas as pd
import joblib
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split

print("Starting Preprocessing...")
print("==================================================")

# ----------------------------------------------------
# 1. LOAD DATA
# ----------------------------------------------------
df = pd.read_csv("backend/data/housing_data.csv")

print("Dataset Loaded:", df.shape)

# ----------------------------------------------------
# 2. CLEANING
# ----------------------------------------------------
df = df.drop_duplicates()

# Safety fill numeric
df = df.fillna(df.median(numeric_only=True))

# ✅ FIX ADDED HERE (BEFORE ENCODING)
df["area"] = pd.to_numeric(df["area"], errors="coerce")

# ----------------------------------------------------
# 3. ENCODE CATEGORICAL FEATURES
# ----------------------------------------------------
cat_cols = [
    "mainroad",
    "guestroom",
    "basement",
    "hotwaterheating",
    "airconditioning",
    "prefarea",
    "furnishingstatus"
]

encoders = {}

for col in cat_cols:
    le = LabelEncoder()
    df[col] = le.fit_transform(df[col])
    encoders[col] = le

# Save encoders
joblib.dump(encoders, "backend/model/label_encoders.pkl")
print("✓ Encoders saved")

# ----------------------------------------------------
# 4. FEATURES & TARGET
# ----------------------------------------------------
X = df.drop("price", axis=1)
y = df["price"]

joblib.dump(X.columns.tolist(), "backend/model/feature_names.pkl")
print("✓ Feature names saved")

# ----------------------------------------------------
# 5. TRAIN TEST SPLIT
# ----------------------------------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

joblib.dump((X_train, X_test, y_train, y_test),
            "backend/model/splits.pkl")

print("✓ Data splits saved")

# ----------------------------------------------------
print("Preprocessing Completed Successfully")
print("Train Shape:", X_train.shape)
print("Test Shape:", X_test.shape)
