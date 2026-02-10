"""
Generate Kaggle Submission CSV for Flat Price Prediction
This script loads the trained model and generates predictions for submission.
"""

import pandas as pd
import joblib
import os
import numpy as np

# Setup paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(SCRIPT_DIR, "model")
DATA_DIR = os.path.join(SCRIPT_DIR, "data")

print("=" * 80)
print("KAGGLE SUBMISSION GENERATOR - FLAT PRICE PREDICTION")
print("=" * 80)

# Load the trained model
print("\n[1/5] Loading trained model...")
model_path = os.path.join(MODEL_DIR, "random_forest_model.pkl")
model = joblib.load(model_path)
print(f"✓ Model loaded from: {model_path}")

# Load the test split
print("\n[2/5] Loading test data...")
splits_path = os.path.join(MODEL_DIR, "splits.pkl")
X_train, X_test, y_train, y_test = joblib.load(splits_path)
print(f"✓ Test data loaded: {X_test.shape[0]} samples, {X_test.shape[1]} features")

# Load feature names
print("\n[3/5] Loading feature configuration...")
feature_names_path = os.path.join(MODEL_DIR, "feature_names.pkl")
feature_names = joblib.load(feature_names_path)
print(f"✓ Features: {', '.join(feature_names)}")

# Generate predictions
print("\n[4/5] Generating predictions...")
predictions = model.predict(X_test)
print(f"✓ Generated {len(predictions)} predictions")
print(f"  - Min prediction: ₹{predictions.min():,.0f}")
print(f"  - Max prediction: ₹{predictions.max():,.0f}")
print(f"  - Mean prediction: ₹{predictions.mean():,.0f}")
print(f"  - Median prediction: ₹{np.median(predictions):,.0f}")

# Create submission DataFrame
print("\n[5/5] Creating submission file...")
submission_df = pd.DataFrame({
    'index': range(len(predictions)),
    'price': predictions.astype(int)
})

# Save to CSV
output_path = os.path.join(SCRIPT_DIR, "kaggle_submission.csv")
submission_df.to_csv(output_path, index=False)

print(f"✓ Submission file created: {output_path}")
print(f"\n{'=' * 80}")
print("SUBMISSION SUMMARY")
print("=" * 80)
print(f"Total predictions: {len(submission_df)}")
print(f"Columns: {', '.join(submission_df.columns)}")
print(f"\nFirst 5 predictions:")
print(submission_df.head())
print(f"\nLast 5 predictions:")
print(submission_df.tail())

# Model performance on test set (for reference)
print(f"\n{'=' * 80}")
print("MODEL PERFORMANCE ON TEST SET (Reference)")
print("=" * 80)
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

mae = mean_absolute_error(y_test, predictions)
rmse = np.sqrt(mean_squared_error(y_test, predictions))
r2 = r2_score(y_test, predictions)

print(f"MAE:  ₹{mae:,.0f}")
print(f"RMSE: ₹{rmse:,.0f}")
print(f"R²:   {r2:.4f}")

print(f"\n{'=' * 80}")
print("✅ KAGGLE SUBMISSION FILE READY!")
print("=" * 80)
print(f"\n📁 File location: {output_path}")
print(f"📊 Format: CSV with columns 'index' and 'price'")
print(f"🎯 Ready to upload to Kaggle!")
