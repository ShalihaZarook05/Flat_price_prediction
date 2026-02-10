from app import app, db
from models import Admin
from werkzeug.security import generate_password_hash

# Default admin credentials
ADMIN_EMAIL = "admin@flatprice.com"
ADMIN_PASSWORD = "admin123"

with app.app_context():
    # Create all tables
    db.create_all()
    
    # Check if admin already exists
    existing_admin = Admin.query.filter_by(email=ADMIN_EMAIL).first()
    
    if existing_admin:
        print(f"⚠️  Admin already exists: {ADMIN_EMAIL}")
    else:
        # Create new admin
        hashed_password = generate_password_hash(ADMIN_PASSWORD)
        admin = Admin(
            email=ADMIN_EMAIL,
            password=hashed_password,
            role='admin'
        )
        
        db.session.add(admin)
        db.session.commit()
        
        print("✅ Admin created successfully!")
        print(f"   Email: {ADMIN_EMAIL}")
        print(f"   Password: {ADMIN_PASSWORD}")
        print("\n⚠️  IMPORTANT: Change this password in production!")
