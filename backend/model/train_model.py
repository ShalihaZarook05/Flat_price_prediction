import joblib
import numpy as np
import pandas as pd

from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.impute import SimpleImputer
from sklearn.pipeline import Pipeline

import matplotlib.pyplot as plt

print("Starting Random Forest Training...")
print("================================================")

# ----------------------------------------------------
# 1. LOAD PREPROCESSED DATA
# ----------------------------------------------------
X_train, X_test, y_train, y_test = joblib.load("splits.pkl")

print("Train Shape:", X_train.shape)
print("Test Shape :", X_test.shape)

# ----------------------------------------------------
# 2. CREATE PIPELINE WITH IMPUTER
# ----------------------------------------------------
pipeline = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("model", RandomForestRegressor(
        n_estimators=120,
        max_depth=20,
        min_samples_split=2,
        random_state=42
    ))
])

# ----------------------------------------------------
# 3. TRAIN MODEL
# ----------------------------------------------------
pipeline.fit(X_train, y_train)

# ----------------------------------------------------
# 4. EVALUATION
# ----------------------------------------------------
y_pred = pipeline.predict(X_test)

mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))
r2 = r2_score(y_test, y_pred)

print("\nMODEL PERFORMANCE")
print("----------------------")
print("MAE  :", round(mae,2))
print("RMSE :", round(rmse,2))
print("R2   :", round(r2,3))

# ----------------------------------------------------
# 5. FEATURE IMPORTANCE
# ----------------------------------------------------
features = X_train.columns
importances = pipeline.named_steps["model"].feature_importances_

fi = pd.DataFrame({
    "feature": features,
    "importance": importances
}).sort_values(by="importance", ascending=False)

print("\nFeature Importance:")
print(fi)

plt.figure(figsize=(8,6))
plt.barh(fi["feature"], fi["importance"])
plt.title("Random Forest Feature Importance")
plt.tight_layout()
plt.savefig("feature_importance.png")
plt.close()

# ----------------------------------------------------
# 6. SAVE PIPELINE MODEL
# ----------------------------------------------------
joblib.dump(pipeline, "random_forest_model.pkl")

print("\nModel Saved Successfully with Imputer ✅")
