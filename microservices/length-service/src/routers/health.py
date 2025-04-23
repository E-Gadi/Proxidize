from fastapi import APIRouter
from src.models import HealthResponse

router = APIRouter(prefix="/health", tags=["health"])


@router.get("/", response_model=HealthResponse)
async def health_check():
    return {"status": "healthy"}
