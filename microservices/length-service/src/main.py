from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from prometheus_client import Gauge
import time, threading

from src.core.handlers import register_exception_handlers
from src.core.observability import setup_observability
from src.routers import length_router, health_router
from src.config import get_settings

app = FastAPI(title="Length Service", version=get_settings().app_version)

origins = [
    "http://localhost:8080",
    "http://localhost",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

setup_observability(app)
register_exception_handlers(app)

app.include_router(length_router)
app.include_router(health_router)

START_TIME = time.time()
UPTIME = Gauge("app_uptime_seconds", "Application uptime in seconds")


def update_uptime():
    while True:
        UPTIME.set(time.time() - START_TIME)
        time.sleep(5)


@app.on_event("startup")
def start_uptime_updater():
    threading.Thread(target=update_uptime, daemon=True).start()



@app.get("/")
def read_root():
    return {"message": "Length Service!"}
