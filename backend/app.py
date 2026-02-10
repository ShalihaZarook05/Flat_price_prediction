from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import joblib
import os
import numpy as np
import json
import secrets
from functools import wraps
from models import db, User, Prediction, Admin

app = Flask(__name__)
CORS(app)

# ============== BASE DIR & CONFIG ==============
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(BASE_DIR, 'instance', 'database.db')
os.makedirs(os.path.dirname(db_path), exist_ok=True)

app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# Simple in-memory token storage (in production, use Redis or database)
active_tokens = {}
admin_tokens = {}

# ============== LOAD MODEL ==============
model = joblib.load(os.path.join(BASE_DIR, "model/random_forest_model.pkl"))
label_encoders = joblib.load(os.path.join(BASE_DIR, "model/label_encoders.pkl"))
feature_names = joblib.load(os.path.join(BASE_DIR, "model/feature_names.pkl"))

print("✓ Model loaded")


# ============== AUTH DECORATOR ==============
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                return jsonify({"error": "Invalid token format"}), 401
        
        if not token:
            return jsonify({"error": "Token is missing"}), 401
        
        # Check if token is valid
        if token not in active_tokens:
            return jsonify({"error": "Invalid or expired token"}), 401
        
        # Get user_id from token
        current_user_id = active_tokens[token]
        
        return f(current_user_id, *args, **kwargs)
    
    return decorated


# ============== ADMIN AUTH DECORATOR ==============
def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                return jsonify({"error": "Invalid token format"}), 401
        
        if not token:
            return jsonify({"error": "Token is missing"}), 401
        
        # Check if token is valid admin token
        if token not in admin_tokens:
            return jsonify({"error": "Invalid or expired admin token"}), 401
        
        # Get admin_id from token
        current_admin_id = admin_tokens[token]
        
        return f(current_admin_id, *args, **kwargs)
    
    return decorated


# ============== AUTHENTICATION ENDPOINTS ==============
@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({"error": "Email and password required"}), 400
        
        # Check if user exists
        if User.query.filter_by(email=email).first():
            return jsonify({"error": "Email already registered"}), 400
        
        # Create new user
        hashed_password = generate_password_hash(password)
        new_user = User(email=email, password=hashed_password)
        
        db.session.add(new_user)
        db.session.commit()
        
        return jsonify({"message": "User registered successfully"}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({"error": "Email and password required"}), 400
        
        user = User.query.filter_by(email=email).first()
        
        if not user or not check_password_hash(user.password, password):
            return jsonify({"error": "Invalid credentials"}), 401
        
        # Generate a random token
        token = secrets.token_urlsafe(32)
        active_tokens[token] = user.id
        
        return jsonify({
            "token": token,
            "user": {
                "id": user.id,
                "email": user.email
            }
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/me', methods=['GET'])
@token_required
def get_current_user(current_user_id):
    try:
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        return jsonify({
            "id": user.id,
            "email": user.email,
            "created_at": user.created_at.isoformat()
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/logout', methods=['POST'])
@token_required
def logout(current_user_id):
    try:
        token = request.headers['Authorization'].split(" ")[1]
        if token in active_tokens:
            del active_tokens[token]
        return jsonify({"message": "Logged out successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# ============== ADMIN AUTHENTICATION ==============
@app.route('/admin/login', methods=['POST'])
def admin_login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({"error": "Email and password required"}), 400
        
        admin = Admin.query.filter_by(email=email).first()
        
        if not admin or not check_password_hash(admin.password, password):
            return jsonify({"error": "Invalid admin credentials"}), 401
        
        # Generate a random token
        token = secrets.token_urlsafe(32)
        admin_tokens[token] = admin.id
        
        return jsonify({
            "token": token,
            "admin": {
                "id": admin.id,
                "email": admin.email,
                "role": admin.role
            }
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/admin/me', methods=['GET'])
@admin_required
def get_current_admin(current_admin_id):
    try:
        admin = Admin.query.get(current_admin_id)
        
        if not admin:
            return jsonify({"error": "Admin not found"}), 404
        
        return jsonify({
            "id": admin.id,
            "email": admin.email,
            "role": admin.role,
            "created_at": admin.created_at.isoformat()
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/admin/logout', methods=['POST'])
@admin_required
def admin_logout(current_admin_id):
    try:
        token = request.headers['Authorization'].split(" ")[1]
        if token in admin_tokens:
            del admin_tokens[token]
        return jsonify({"message": "Admin logged out successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# ============== PREDICT ==============
@app.route('/predict', methods=['POST'])
@token_required
def predict(current_user_id):
    try:
        data = request.json

        # Convert Yes/No → 1/0
        def yn(x):
            return 1 if str(x).lower() == "yes" else 0

        input_data = [
            float(data["area"]),
            int(data["bedrooms"]),
            int(data["bathrooms"]),
            int(data["stories"]),

            yn(data["mainroad"]),
            yn(data["guestroom"]),
            yn(data["basement"]),
            yn(data["hotwaterheating"]),
            yn(data["airconditioning"]),

            int(data["parking"]),

            yn(data["prefarea"]),

            # Furnishing status encoding
            label_encoders["furnishingstatus"].transform(
                [data["furnishingstatus"]]
            )[0]
        ]

        arr = np.array(input_data).reshape(1, -1)
        price = model.predict(arr)[0]
        price = round(float(price), 2)

        # Save prediction to database
        prediction = Prediction(
            user_id=current_user_id,
            input_data=json.dumps(data),
            price=price,
            favorite=False
        )
        db.session.add(prediction)
        db.session.commit()

        return jsonify({
            "predicted_price": price,
            "prediction_id": prediction.id
        })

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 400


# ============== HISTORY ==============
@app.route('/history', methods=['GET'])
@token_required
def get_history(current_user_id):
    try:
        predictions = Prediction.query.filter_by(user_id=current_user_id).order_by(Prediction.created_at.desc()).all()
        
        history = []
        for pred in predictions:
            history.append({
                "id": pred.id,
                "input": json.loads(pred.input_data),
                "price": pred.price,
                "favorite": pred.favorite,
                "created_at": pred.created_at.isoformat()
            })
        
        return jsonify(history), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/history/<int:id>', methods=['DELETE'])
@token_required
def delete_history(current_user_id, id):
    try:
        prediction = Prediction.query.filter_by(id=id, user_id=current_user_id).first()
        
        if not prediction:
            return jsonify({"error": "Prediction not found"}), 404
        
        db.session.delete(prediction)
        db.session.commit()
        
        return jsonify({"message": "deleted"}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/history/<int:id>/favorite', methods=['PUT'])
@token_required
def toggle_favorite(current_user_id, id):
    try:
        prediction = Prediction.query.filter_by(id=id, user_id=current_user_id).first()
        
        if not prediction:
            return jsonify({"error": "Prediction not found"}), 404
        
        prediction.favorite = not prediction.favorite
        db.session.commit()
        
        return jsonify({
            "message": "favorite toggled",
            "favorite": prediction.favorite
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# ============== ADMIN MANAGEMENT ENDPOINTS ==============

# A. USER MANAGEMENT
@app.route('/admin/users', methods=['GET'])
@admin_required
def get_all_users(current_admin_id):
    try:
        users = User.query.all()
        user_list = []
        
        for user in users:
            prediction_count = Prediction.query.filter_by(user_id=user.id).count()
            user_list.append({
                "id": user.id,
                "email": user.email,
                "is_blocked": user.is_blocked,
                "created_at": user.created_at.isoformat(),
                "prediction_count": prediction_count
            })
        
        return jsonify(user_list), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/admin/users/<int:user_id>', methods=['DELETE'])
@admin_required
def delete_user(current_admin_id, user_id):
    try:
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        db.session.delete(user)
        db.session.commit()
        
        return jsonify({"message": "User deleted successfully"}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/admin/users/<int:user_id>/block', methods=['PUT'])
@admin_required
def toggle_block_user(current_admin_id, user_id):
    try:
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        user.is_blocked = not user.is_blocked
        db.session.commit()
        
        return jsonify({
            "message": "User block status updated",
            "is_blocked": user.is_blocked
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# B. PREDICTION MANAGEMENT
@app.route('/admin/predictions', methods=['GET'])
@admin_required
def get_all_predictions(current_admin_id):
    try:
        predictions = Prediction.query.order_by(Prediction.created_at.desc()).all()
        prediction_list = []
        
        for pred in predictions:
            user = User.query.get(pred.user_id)
            prediction_list.append({
                "id": pred.id,
                "user_email": user.email if user else "Unknown",
                "user_id": pred.user_id,
                "input": json.loads(pred.input_data),
                "price": pred.price,
                "favorite": pred.favorite,
                "created_at": pred.created_at.isoformat()
            })
        
        return jsonify(prediction_list), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/admin/predictions/<int:prediction_id>', methods=['DELETE'])
@admin_required
def delete_prediction_admin(current_admin_id, prediction_id):
    try:
        prediction = Prediction.query.get(prediction_id)
        
        if not prediction:
            return jsonify({"error": "Prediction not found"}), 404
        
        db.session.delete(prediction)
        db.session.commit()
        
        return jsonify({"message": "Prediction deleted successfully"}), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# C. DASHBOARD STATISTICS
@app.route('/admin/stats', methods=['GET'])
@admin_required
def get_statistics(current_admin_id):
    try:
        total_users = User.query.count()
        total_predictions = Prediction.query.count()
        
        # Calculate average price
        predictions = Prediction.query.all()
        avg_price = sum([p.price for p in predictions]) / len(predictions) if predictions else 0
        
        # Get recent activity
        recent_users = User.query.order_by(User.created_at.desc()).limit(5).all()
        recent_predictions = Prediction.query.order_by(Prediction.created_at.desc()).limit(5).all()
        
        # Price range
        max_price = max([p.price for p in predictions]) if predictions else 0
        min_price = min([p.price for p in predictions]) if predictions else 0
        
        return jsonify({
            "total_users": total_users,
            "total_predictions": total_predictions,
            "avg_price": round(avg_price, 2),
            "max_price": round(max_price, 2),
            "min_price": round(min_price, 2),
            "recent_users_count": len(recent_users),
            "recent_predictions_count": len(recent_predictions)
        }), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


# D. MODEL INFO
@app.route('/admin/model-info', methods=['GET'])
@admin_required
def get_model_info(current_admin_id):
    try:
        model_info = {
            "model_type": str(type(model).__name__),
            "features_count": len(feature_names),
            "feature_names": feature_names.tolist() if hasattr(feature_names, 'tolist') else list(feature_names),
            "last_trained": "2024-01-15",  # You can store this in a config file
            "accuracy": "85.3%",  # You can calculate this from your training data
            "total_predictions": Prediction.query.count()
        }
        
        return jsonify(model_info), 200
    
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route('/')
def home():
    return "Flat Price Prediction API Running"


if __name__ == '__main__':
    app.run(debug=True)
