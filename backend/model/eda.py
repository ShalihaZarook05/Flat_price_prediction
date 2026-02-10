"""
Exploratory Data Analysis (EDA) Script for Flat Price Prediction
This script performs comprehensive data analysis and visualization
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# Set visualization style
sns.set_style('whitegrid')
plt.rcParams['figure.figsize'] = (12, 8)


class FlatPriceEDA:
    """
    Exploratory Data Analysis class for flat price prediction dataset
    """

    def __init__(self, data_path):
        self.data_path = data_path
        self.df = None
        self.numeric_cols = None
        self.categorical_cols = None

    def load_data(self):
        """Load the dataset"""
        try:
            self.df = pd.read_csv(self.data_path)
            print(f"✓ Data loaded successfully: {self.df.shape[0]} rows, {self.df.shape[1]} columns")
            return self.df
        except Exception as e:
            print(f"✗ Error loading data: {e}")
            return None

    def basic_info(self):
        if self.df is None:
            print("Please load data first using load_data()")
            return

        print("\n==== BASIC DATASET INFORMATION ====")
        print(f"\nDataset Shape: {self.df.shape}")
        print("\nColumn Types:")
        print(self.df.dtypes)

        print("\nFirst Few Rows:")
        print(self.df.head())

    def identify_columns(self):
        self.numeric_cols = self.df.select_dtypes(include=[np.number]).columns.tolist()
        self.categorical_cols = self.df.select_dtypes(include=['object', 'category']).columns.tolist()

        print("\n==== COLUMN TYPES ====")
        print("Numeric:", self.numeric_cols)
        print("Categorical:", self.categorical_cols)

    def missing_values_analysis(self):
        print("\n==== MISSING VALUES ====")

        missing = pd.DataFrame({
            'Missing_Count': self.df.isnull().sum(),
            'Missing_Percentage': (self.df.isnull().sum() / len(self.df)) * 100
        })

        print(missing)

    def statistical_summary(self):
        print("\n==== STATISTICAL SUMMARY ====")
        print(self.df.describe())

    def correlation_analysis(self, target_column=None):
        print("\n==== CORRELATION ANALYSIS ====")

        corr_matrix = self.df[self.numeric_cols].corr()
        print(corr_matrix)

        plt.figure(figsize=(10, 6))
        sns.heatmap(corr_matrix, annot=True, cmap='coolwarm')
        plt.title("Correlation Heatmap")
        plt.savefig("correlation_heatmap.png")
        plt.close()

        if target_column:
            print("\nCorrelation with target:")
            print(corr_matrix[target_column].sort_values(ascending=False))

    def distribution_plots(self):
        print("\n==== DISTRIBUTION PLOTS ====")

        for col in self.numeric_cols:
            plt.figure(figsize=(6, 4))
            sns.histplot(self.df[col], bins=30)
            plt.title(f"Distribution of {col}")
            plt.savefig(f"{col}_distribution.png")
            plt.close()

    def run_full_eda(self, target_column=None):
        self.load_data()
        self.basic_info()
        self.identify_columns()
        self.missing_values_analysis()
        self.statistical_summary()
        self.distribution_plots()
        self.correlation_analysis(target_column)


# ================= MAIN FUNCTION ==================

def main():
    """
    MAIN EXECUTION
    """

    # ✅ CORRECT PATH FIXED HERE
    df = pd.read_csv("backend/data/housing_data.csv")

    print("Dataset Shape:", df.shape)
    print("\nColumns:")
    print(df.columns)

    print("\nMissing Values:")
    print(df.isnull().sum())

    print("\nStatistical Summary:")
    print(df.describe())

    print("\nCorrelation with Price:")
    print(df.corr(numeric_only=True)["price"].sort_values(ascending=False))

    # Price distribution
    plt.figure(figsize=(8, 5))
    sns.histplot(df["price"], bins=30)
    plt.title("Price Distribution")
    plt.savefig("price_distribution.png")
    plt.close()

    # Correlation heatmap
    plt.figure(figsize=(10, 6))
    sns.heatmap(df.corr(numeric_only=True), annot=True)
    plt.title("Correlation Heatmap")
    plt.savefig("correlation_heatmap.png")
    plt.close()

    # OPTIONAL CLASS RUN
    DATA_PATH = "backend/data/housing_data.csv"
    TARGET_COLUMN = "price"

    eda = FlatPriceEDA(DATA_PATH)
    eda.run_full_eda(target_column=TARGET_COLUMN)


if __name__ == "__main__":
    main()
