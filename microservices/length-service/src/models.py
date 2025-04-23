from typing import List, Optional
from pydantic import BaseModel


class LengthRequest(BaseModel):
    input_string: str


class LengthResponse(BaseModel):
    length: int


class HealthResponse(BaseModel):
    status: str


class ErrorResponse(BaseModel):
    message: str
    type: str
    details: Optional[List[dict]] = None
