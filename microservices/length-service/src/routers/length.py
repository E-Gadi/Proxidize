from fastapi import APIRouter, Request
from src.models import LengthRequest, LengthResponse
from src.services.length_service import compute_length
from src.dependencies import TracerDep

router = APIRouter(prefix="/length", tags=["length"])


@router.post("/", response_model=LengthResponse)
async def get_length(request: Request, data: LengthRequest, tracer: TracerDep):
    with tracer.start_as_current_span("length-endpoint"):
        return {"length": compute_length(data.input_string)}
