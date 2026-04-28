import logging
import time
from fastapi import FastAPI, Request, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
from pythonjsonlogger import jsonlogger

# Logger setup
logger = logging.getLogger("platform-api")
logHandler = logging.StreamHandler()
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

app = FastAPI(title="DevOps Platform Hub API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    logger.info(f"Path: {request.url.path} Duration: {duration:.4f}s Status: {response.status_code}")
    return response

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/platform/provision")
def provision_platform(catalog_item_id: str, params: dict):
    logger.info(f"Provisioning platform item {catalog_item_id} with params {params}")
    return {"status": "Provisioning Job Enqueued", "job_id": "job_sec_123"}

@app.get("/catalog/services")
def get_catalog_services():
    return [
        {"id": "svc-go", "name": "Go Microservice", "category": "Backend", "status": "AVAILABLE"},
        {"id": "svc-react", "name": "React SPA", "category": "Frontend", "status": "AVAILABLE"},
        {"id": "svc-data", "name": "Kafka Stream", "category": "Data", "status": "DEPRECATED"}
    ]

@app.post("/pipelines/run")
def run_pipeline(pipeline_id: str, branch: str = "main"):
    logger.info(f"Triggering pipeline {pipeline_id} on branch {branch}")
    return {"status": "Pipeline Triggered", "run_id": "run_sec_456"}

@app.get("/scores/summary")
def get_scores_summary():
    return {
        "platform_maturity_index": 0.912,
        "dora_velocity_rating": "Elite",
        "reliability_index": 0.98,
        "security_compliance": "OPTIMAL"
    }

@app.get("/dashboard/summary")
def get_dashboard_summary():
    return {
        "total_managed_services": 452,
        "avg_provisioning_time": "14m",
        "zero_drift_compliance": "98%",
        "platform_roi_est": "$4.2M / year"
    }
