"""
Main preprocessing script for flat price prediction.

This script performs the complete data preprocessing pipeline:
1. Load dataset
2. Remove duplicates
3. Handle missing values
4. Encode categorical features
5. Select features and target
6. Train/test split
7. Save all artifacts

Usage:
    python preprocess.py
"""

import pandas as pd
import joblib
import os
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split

# Ensure paths work regardless of where script is run from
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(SCRIPT_DIR, "data")
MODEL_DIR = os.path.join(SCRIPT_DIR, "model")

# Create directories if they don't exist
os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)


def load_and_clean_data(file_path):
    """Load dataset and perform basic cleaning."""
    print("="*60)
    print("STEP 1: LOADING AND CLEANING DATA")
    print("="*60)
    
    if not os.path.exists(file_path):
        print(f"\n❌ ERROR: Data file not found at {file_path}")
        print("\nPlease ensure the housing_data.csv file exists in the data directory.")
        return None
    
    print(f"\n✓ Loading dataset from: {file_path}")
    
    # Load dataset
    df = pd.read_csv(file_path)
    print(f"  - Original shape: {df.shape}")
    print(f"  - Columns: {df.columns.tolist()}")
    
    # Remove duplicates
    original_rows = len(df)
    df = df.drop_duplicates()
    duplicates_removed = original_rows - len(df)
    print(f"\n✓ Duplicates removed: {duplicates_removed}")
    
    # Fill missing numeric values with median
    num_cols = df.select_dtypes(include=['int64', 'float64']).columns
    
    missing_info = {}
    for col in num_cols:
        missing_count = df[col].isna().sum()
        if missing_count > 0:
            missing_info[col] = missing_count
            df[col].fillna(df[col].median(), inplace=True)
    
    if missing_info:
        print("\n✓ Missing values filled (with median):")
        for col, count in missing_info.items():
            print(f"  - {col}: {count} missing values")
    else:
        print("\n✓ No missing values found in numeric columns")
    
    print(f"\n✓ Cleaned dataset shape: {df.shape}")
    
    return df


def encode_categorical_features(df):
    """Encode categorical features using LabelEncoder."""
    print("\n" + "="*60)
    print("STEP 2: ENCODING CATEGORICAL FEATURES")
    print("="*60)
    
    # Get categorical columns
    cat_cols = df.select_dtypes(include=['object']).columns
    
    if len(cat_cols) == 0:
        print("\n✓ No categorical columns found to encode.")
        return df, {}
    
    print(f"\n✓ Found {len(cat_cols)} categorical columns: {cat_cols.tolist()}")
    
    encoders = {}
    df_encoded = df.copy()
    
    for col in cat_cols:
        print(f"\n  Encoding: {col}")
        unique_values = df_encoded[col].nunique()
        print(f"    - Unique values: {unique_values}")
        
        le = LabelEncoder()
        df_encoded[col] = le.fit_transform(df_encoded[col])
        encoders[col] = le
        
        print(f"    - Encoded range: [{df_encoded[col].min()}, {df_encoded[col].max()}]")
    
    # Save encoders for Flask
    encoder_path = os.path.join(MODEL_DIR, "label_encoders.pkl")
    joblib.dump(encoders, encoder_path)
    print(f"\n✓ Label encoders saved to: {encoder_path}")
    
    return df_encoded, encoders


def select_features_and_target(df, target_column="price"):
    """Separate features and target variable."""
    print("\n" + "="*60)
    print("STEP 3: SELECTING FEATURES AND TARGET")
    print("="*60)
    
    if target_column not in df.columns:
        print(f"\n❌ ERROR: Target column '{target_column}' not found in dataset!")
        print(f"Available columns: {df.columns.tolist()}")
        return None, None
    
    # Separate features and target
    X = df.drop(target_column, axis=1)
    y = df[target_column]
    
    print(f"\n✓ Target column: {target_column}")
    print(f"  - Shape: {y.shape}")
    print(f"  - Data type: {y.dtype}")
    print(f"  - Range: [{y.min():.2f}, {y.max():.2f}]")
    print(f"  - Mean: {y.mean():.2f}")
    print(f"  - Median: {y.median():.2f}")
    
    print(f"\n✓ Features (X):")
    print(f"  - Shape: {X.shape}")
    print(f"  - Number of features: {X.shape[1]}")
    print(f"  - Feature names: {X.columns.tolist()}")
    
    # Save feature names for Flask
    feature_names_path = os.path.join(MODEL_DIR, "feature_names.pkl")
    joblib.dump(X.columns.tolist(), feature_names_path)
    print(f"\n✓ Feature names saved to: {feature_names_path}")
    
    return X, y


def split_train_test(X, y, test_size=0.2, random_state=42):
    """Split data into training and testing sets."""
    print("\n" + "="*60)
    print("STEP 4: TRAIN/TEST SPLIT")
    print("="*60)
    
    # Perform train/test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state
    )
    
    print(f"\n✓ Split parameters:")
    print(f"  - Test size: {test_size*100:.0f}%")
    print(f"  - Random state: {random_state}")
    
    print(f"\n✓ Training set:")
    print(f"  - X_train shape: {X_train.shape}")
    print(f"  - y_train shape: {y_train.shape}")
    print(f"  - Samples: {len(X_train)}")
    
    print(f"\n✓ Testing set:")
    print(f"  - X_test shape: {X_test.shape}")
    print(f"  - y_test shape: {y_test.shape}")
    print(f"  - Samples: {len(X_test)}")
    
    print(f"\n✓ Target statistics:")
    print(f"  - Train mean: {y_train.mean():.2f}, std: {y_train.std():.2f}")
    print(f"  - Test mean: {y_test.mean():.2f}, std: {y_test.std():.2f}")
    
    # Save splits
    splits_path = os.path.join(MODEL_DIR, "splits.pkl")
    joblib.dump((X_train, X_test, y_train, y_test), splits_path)
    print(f"\n✓ Train/test splits saved to: {splits_path}")
    
    return X_train, X_test, y_train, y_test


def main():
    """Main preprocessing pipeline."""
    print("\n" + "="*60)
    print("FLAT PRICE PREDICTION - DATA PREPROCESSING")
    print("="*60)
    
    # Define paths
    data_path = os.path.join(DATA_DIR, "housing_data.csv")
    processed_data_path = os.path.join(DATA_DIR, "housing_data_processed.csv")
    
    # Step 1: Load and clean data
    df = load_and_clean_data(data_path)
    
    if df is None:
        return
    
    # Step 2: Encode categorical features
    df_encoded, encoders = encode_categorical_features(df)
    
    # Step 3: Select features and target
    X, y = select_features_and_target(df_encoded, target_column="price")
    
    if X is None or y is None:
        print("\n❌ ERROR: Could not prepare features and target!")
        return
    
    # Step 4: Split into train and test sets
    X_train, X_test, y_train, y_test = split_train_test(X, y, test_size=0.2, random_state=42)
    
    # Save processed data
    df_encoded.to_csv(processed_data_path, index=False)
    print(f"\n✓ Processed data saved to: {processed_data_path}")
    
    # Final summary
    print("\n" + "="*60)
    print("PREPROCESSING COMPLETED SUCCESSFULLY!")
    print("="*60)
    
    print(f"\n📁 Files created:")
    print(f"  ✓ {processed_data_path}")
    print(f"  ✓ {os.path.join(MODEL_DIR, 'label_encoders.pkl')}")
    print(f"  ✓ {os.path.join(MODEL_DIR, 'feature_names.pkl')}")
    print(f"  ✓ {os.path.join(MODEL_DIR, 'splits.pkl')}")
    
    print(f"\n📊 Dataset summary:")
    print(f"  - Total samples: {len(df_encoded)}")
    print(f"  - Training samples: {len(X_train)} ({len(X_train)/len(df_encoded)*100:.0f}%)")
    print(f"  - Testing samples: {len(X_test)} ({len(X_test)/len(df_encoded)*100:.0f}%)")
    print(f"  - Number of features: {X.shape[1]}")
    
    print("\nPreprocessing Completed")
    print("Train Shape:", X_train.shape)
    print("Test Shape:", X_test.shape)
    
    print("\n🚀 Ready for model training!")


if __name__ == "__main__":
    main()
