import joblib

# Load saved objects
enc = joblib.load("backend/model/label_encoders.pkl")
features = joblib.load("backend/model/feature_names.pkl")

print("Encoders Loaded For Columns:")
for k in enc.keys():
    print(" -", k)

print("\nFeature Order:")
print(features)
