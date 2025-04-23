from fastapi import APIRouter, Request
from src.models import HashRequest, HashResponse
from src.services.hash_service import compute_hash
from src.dependencies import TracerDep

router = APIRouter(prefix="/hash", tags=["hash"])


@router.post("/", response_model=HashResponse)
async def create_hash(request: Request, data: HashRequest, tracer: TracerDep):
    with tracer.start_as_current_span("hash-endpoint"):
        return {"hash": compute_hash(data.input_string)}
