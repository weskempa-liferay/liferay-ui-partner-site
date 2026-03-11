import json
import base64
from pathlib import Path

config_path = Path("config.json")

with config_path.open("r", encoding="utf-8") as f:
    config = json.load(f)

email = config["admin"]["emailDefault"]
password = config["admin"]["passwordDefault"]

credentials = f"{email}:{password}"
token = base64.b64encode(credentials.encode("utf-8")).decode("utf-8")

print(f"Authorization: Basic {token}")
