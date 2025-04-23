from typing import List, Optional
from pydantic import BaseModel


class HashRequest(BaseModel):
    input_string: str


class HashResponse(BaseModel):
    hash: str


class HealthResponse(BaseModel):
    status: str


class ErrorResponse(BaseModel):
    message: str
    type: str
    details: Optional[List[dict]] = None
