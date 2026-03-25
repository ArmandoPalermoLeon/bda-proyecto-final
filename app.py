from flask import Flask
from dotenv import load_dotenv
import os

from routes.public import init_routes as public_routes
from routes.admin import init_routes as admin_routes
from routes.clinica import init_routes as clinica_routes

load_dotenv()

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "clave-secreta-dev")

public_routes(app)
admin_routes(app)
clinica_routes(app)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5002)
