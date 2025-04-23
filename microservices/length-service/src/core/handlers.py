from fastapi.responses import JSONResponse

from src.models import ErrorResponse
from src.core.exceptions import LengthServiceError


async def length_service_error_handler(_, exc: LengthServiceError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            message=exc.detail,
            type=exc.__class__.__name__.lower(),
            details=exc.details,
        ).dict(),
    )


def register_exception_handlers(app):
    app.add_exception_handler(LengthServiceError, length_service_error_handler)