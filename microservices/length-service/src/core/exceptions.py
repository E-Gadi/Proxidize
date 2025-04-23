from fastapi import HTTPException, status
from typing import Optional, Dict, Any


class LengthServiceError(HTTPException):
    def __init__(
        self, detail: str, status_code: int, details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(status_code=status_code, detail=detail)
        self.details = details


class InvalidInputError(LengthServiceError):
    def __init__(
        self, detail: str = "Invalid input", details: Optional[Dict[str, Any]] = None
    ):
        super().__init__(
            detail=detail, status_code=status.HTTP_400_BAD_REQUEST, details=details
        )


class LengthComputationError(LengthServiceError):
    def __init__(
        self,
        detail: str = "Length computation failed",
        details: Optional[Dict[str, Any]] = None,
    ):
        super().__init__(
            detail=detail,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=details,
        )