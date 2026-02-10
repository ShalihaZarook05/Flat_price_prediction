"""
Data loading and basic cleaning module for flat price prediction.

This module handles:
- Loading the housing dataset
- Removing duplicates
- Handling missing values
- Basic data validation
"""

import pandas as pd
import joblib
import os
import sys
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def load_and_clean_data(file_path="../data/housing_data.csv"):
    """
    Load dataset and perform basic cleaning operations.
    
    Args:
        file_path: Path to the housing data CSV file
        
    Returns:
        pandas DataFrame: Cleaned dataset
    """
    print(f"Loading dataset from: {file_path}")
    
    # Load dataset
    df = pd.read_csv(file_path)
    
    print(f"Original dataset shape: {df.shape}")
    print(f"Original columns: {df.columns.tolist()}")
    
    # Remove duplicates
    original_rows = len(df)
    df = df.drop_duplicates()
    duplicates_removed = original_rows - len(df)
    print(f"Duplicates removed: {duplicates_removed}")
    
    # Fill missing numeric values with median
    num_cols = df.select_dtypes(include=['int64', 'float64']).columns
    
    missing_info = {}
    for col in num_cols:
        missing_count = df[col].isna().sum()
        if missing_count > 0:
            missing_info[col] = missing_count
            df[col].fillna(df[col].median(), inplace=True)
    
    if missing_info:
        print("\nMissing values filled (with median):")
        for col, count in missing_info.items():
            print(f"  - {col}: {count} missing values")
    else:
        print("\nNo missing values found in numeric columns")
    
    print(f"\nCleaned dataset shape: {df.shape}")
    
    return df


def get_data_info(df):
    """
    Get comprehensive information about the dataset.
    
    Args:
        df: pandas DataFrame
        
    Returns:
        dict: Dictionary containing data information
    """
    info = {
        'shape': df.shape,
        'columns': df.columns.tolist(),
        'dtypes': df.dtypes.to_dict(),
        'missing_values': df.isnull().sum().to_dict(),
        'numeric_columns': df.select_dtypes(include=['int64', 'float64']).columns.tolist(),
        'categorical_columns': df.select_dtypes(include=['object', 'category']).columns.tolist(),
        'memory_usage': df.memory_usage(deep=True).sum() / 1024**2  # MB
    }
    
    return info


def display_data_summary(df):
    """
    Display a comprehensive summary of the dataset.
    
    Args:
        df: pandas DataFrame
    """
    print("\n" + "="*60)
    print("DATASET SUMMARY")
    print("="*60)
    
    print(f"\nDataset Shape: {df.shape[0]} rows × {df.shape[1]} columns")
    
    print("\nFirst few rows:")
    print(df.head())
    
    print("\nData Types:")
    print(df.dtypes)
    
    print("\nMissing Values:")
    missing = df.isnull().sum()
    missing_pct = 100 * missing / len(df)
    missing_df = pd.DataFrame({
        'Missing Count': missing,
        'Percentage': missing_pct
    })
    print(missing_df[missing_df['Missing Count'] > 0])
    
    print("\nNumerical Columns Summary:")
    print(df.describe())
    
    categorical_cols = df.select_dtypes(include=['object', 'category']).columns
    if len(categorical_cols) > 0:
        print("\nCategorical Columns:")
        for col in categorical_cols:
            print(f"\n{col}:")
            print(df[col].value_counts().head(10))


def encode_categorical_features(df, save_encoders=True, encoder_path="../model/label_encoders.pkl"):
    """
    Encode categorical features using LabelEncoder.
    
    Args:
        df: pandas DataFrame
        save_encoders: Whether to save the encoders to disk
        encoder_path: Path to save the label encoders
        
    Returns:
        tuple: (encoded_df, encoders_dict)
    """
    print("\n" + "="*60)
    print("ENCODING CATEGORICAL FEATURES")
    print("="*60)
    
    # Create a copy to avoid modifying the original
    df_encoded = df.copy()
    
    # Get categorical columns
    cat_cols = df_encoded.select_dtypes(include=['object']).columns
    
    if len(cat_cols) == 0:
        print("\nNo categorical columns found to encode.")
        return df_encoded, {}
    
    print(f"\nFound {len(cat_cols)} categorical columns: {cat_cols.tolist()}")
    
    encoders = {}
    
    for col in cat_cols:
        print(f"\nEncoding column: {col}")
        unique_values = df_encoded[col].nunique()
        print(f"  - Unique values: {unique_values}")
        print(f"  - Sample values: {df_encoded[col].unique()[:5].tolist()}")
        
        le = LabelEncoder()
        df_encoded[col] = le.fit_transform(df_encoded[col])
        encoders[col] = le
        
        print(f"  - Encoded range: [{df_encoded[col].min()}, {df_encoded[col].max()}]")
    
    # Save encoders for Flask
    if save_encoders:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(encoder_path), exist_ok=True)
        
        joblib.dump(encoders, encoder_path)
        print(f"\n✓ Label encoders saved to: {encoder_path}")
    
    print("\n✓ Categorical encoding completed successfully!")
    
    return df_encoded, encoders


def decode_categorical_features(df, encoders):
    """
    Decode categorical features back to original values.
    
    Args:
        df: pandas DataFrame with encoded features
        encoders: Dictionary of LabelEncoders
        
    Returns:
        pandas DataFrame with decoded categorical features
    """
    df_decoded = df.copy()
    
    for col, encoder in encoders.items():
        if col in df_decoded.columns:
            df_decoded[col] = encoder.inverse_transform(df_decoded[col].astype(int))
    
    return df_decoded


def load_encoders(encoder_path="../model/label_encoders.pkl"):
    """
    Load saved label encoders.
    
    Args:
        encoder_path: Path to the saved encoders
        
    Returns:
        dict: Dictionary of LabelEncoders
    """
    if not os.path.exists(encoder_path):
        print(f"❌ ERROR: Encoders not found at {encoder_path}")
        return None
    
    encoders = joblib.load(encoder_path)
    print(f"✓ Label encoders loaded from: {encoder_path}")
    print(f"  Available encoders: {list(encoders.keys())}")
    
    return encoders


def select_features_and_target(df, target_column="price", save_feature_names=True, 
                                feature_names_path="../model/feature_names.pkl"):
    """
    Separate features and target variable.
    
    Args:
        df: pandas DataFrame
        target_column: Name of the target column (default: "price")
        save_feature_names: Whether to save feature names to disk
        feature_names_path: Path to save feature names
        
    Returns:
        tuple: (X, y) - Features and target
    """
    print("\n" + "="*60)
    print("SELECTING FEATURES AND TARGET")
    print("="*60)
    
    if target_column not in df.columns:
        print(f"❌ ERROR: Target column '{target_column}' not found in dataset!")
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
    if save_feature_names:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(feature_names_path), exist_ok=True)
        
        joblib.dump(X.columns.tolist(), feature_names_path)
        print(f"\n✓ Feature names saved to: {feature_names_path}")
    
    return X, y


def load_feature_names(feature_names_path="../model/feature_names.pkl"):
    """
    Load saved feature names.
    
    Args:
        feature_names_path: Path to the saved feature names
        
    Returns:
        list: List of feature names
    """
    if not os.path.exists(feature_names_path):
        print(f"❌ ERROR: Feature names not found at {feature_names_path}")
        return None
    
    feature_names = joblib.load(feature_names_path)
    print(f"✓ Feature names loaded from: {feature_names_path}")
    print(f"  Number of features: {len(feature_names)}")
    print(f"  Features: {feature_names}")
    
    return feature_names


def split_train_test(X, y, test_size=0.2, random_state=42, save_splits=True, 
                     splits_path="../model/splits.pkl"):
    """
    Split data into training and testing sets.
    
    Args:
        X: Features DataFrame
        y: Target Series
        test_size: Proportion of data for testing (default: 0.2 = 20%)
        random_state: Random state for reproducibility (default: 42)
        save_splits: Whether to save splits to disk
        splits_path: Path to save the splits
        
    Returns:
        tuple: (X_train, X_test, y_train, y_test)
    """
    print("\n" + "="*60)
    print("TRAIN/TEST SPLIT")
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
    if save_splits:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(splits_path), exist_ok=True)
        
        joblib.dump((X_train, X_test, y_train, y_test), splits_path)
        print(f"\n✓ Train/test splits saved to: {splits_path}")
    
    return X_train, X_test, y_train, y_test


def load_splits(splits_path="../model/splits.pkl"):
    """
    Load saved train/test splits.
    
    Args:
        splits_path: Path to the saved splits
        
    Returns:
        tuple: (X_train, X_test, y_train, y_test)
    """
    if not os.path.exists(splits_path):
        print(f"❌ ERROR: Splits not found at {splits_path}")
        return None, None, None, None
    
    X_train, X_test, y_train, y_test = joblib.load(splits_path)
    print(f"✓ Train/test splits loaded from: {splits_path}")
    print(f"  - Training samples: {len(X_train)}")
    print(f"  - Testing samples: {len(X_test)}")
    
    return X_train, X_test, y_train, y_test


def save_cleaned_data(df, output_path="../data/housing_data_cleaned.csv"):
    """
    Save the cleaned dataset to a CSV file.
    
    Args:
        df: pandas DataFrame
        output_path: Path to save the cleaned data
    """
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    df.to_csv(output_path, index=False)
    print(f"\nCleaned data saved to: {output_path}")


def validate_data(df, required_columns=None):
    """
    Validate the dataset for basic requirements.
    
    Args:
        df: pandas DataFrame
        required_columns: List of required column names
        
    Returns:
        bool: True if validation passes, False otherwise
    """
    print("\n" + "="*60)
    print("DATA VALIDATION")
    print("="*60)
    
    is_valid = True
    
    # Check if dataframe is empty
    if df.empty:
        print("❌ ERROR: Dataset is empty!")
        return False
    
    print(f"✓ Dataset contains {len(df)} rows")
    
    # Check for required columns
    if required_columns:
        missing_cols = set(required_columns) - set(df.columns)
        if missing_cols:
            print(f"❌ ERROR: Missing required columns: {missing_cols}")
            is_valid = False
        else:
            print(f"✓ All required columns present: {required_columns}")
    
    # Check for excessive missing values
    missing_threshold = 0.5  # 50%
    high_missing = []
    for col in df.columns:
        missing_pct = df[col].isnull().sum() / len(df)
        if missing_pct > missing_threshold:
            high_missing.append((col, missing_pct))
    
    if high_missing:
        print(f"⚠ WARNING: Columns with >{missing_threshold*100}% missing values:")
        for col, pct in high_missing:
            print(f"  - {col}: {pct*100:.2f}%")
    else:
        print(f"✓ No columns with excessive missing values")
    
    return is_valid


if __name__ == "__main__":
    # Main execution
    print("Housing Data Loader and Cleaner")
    print("="*60)
    
    # Define the data path
    data_path = "../data/housing_data.csv"
    
    # Check if file exists
    if not os.path.exists(data_path):
        print(f"\n❌ ERROR: Data file not found at {data_path}")
        print("\nPlease ensure the housing_data.csv file exists in the data directory.")
        sys.exit(1)
    
    # Load and clean data
    df = load_and_clean_data(data_path)
    
    # Display summary
    display_data_summary(df)
    
    # Validate data
    validate_data(df)
    
    # Encode categorical features
    df_encoded, encoders = encode_categorical_features(df)
    
    # Select features and target
    X, y = select_features_and_target(df_encoded, target_column="price")
    
    if X is not None and y is not None:
        # Split into train and test sets
        X_train, X_test, y_train, y_test = split_train_test(X, y, test_size=0.2, random_state=42)
        
        # Save cleaned and encoded data
        save_cleaned_data(df_encoded, "../data/housing_data_processed.csv")
        
        print("\n" + "="*60)
        print("DATA PREPARATION COMPLETED SUCCESSFULLY!")
        print("="*60)
        print(f"\n📁 Files created:")
        print(f"  ✓ Processed data: ../data/housing_data_processed.csv")
        print(f"  ✓ Label encoders: ../model/label_encoders.pkl")
        print(f"  ✓ Feature names: ../model/feature_names.pkl")
        print(f"  ✓ Train/test splits: ../model/splits.pkl")
        
        print(f"\n📊 Dataset ready for training:")
        print(f"  - Total samples: {len(df_encoded)}")
        print(f"  - Training samples: {len(X_train)} ({len(X_train)/len(df_encoded)*100:.0f}%)")
        print(f"  - Testing samples: {len(X_test)} ({len(X_test)/len(df_encoded)*100:.0f}%)")
        print(f"  - Number of features: {X.shape[1]}")
        print(f"\n🚀 Ready for model training!")
        
        # Verify output
        print("\nPreprocessing Completed")
        print("Train Shape:", X_train.shape)
        print("Test Shape:", X_test.shape)
    else:
        print("\n❌ ERROR: Could not prepare features and target!")
