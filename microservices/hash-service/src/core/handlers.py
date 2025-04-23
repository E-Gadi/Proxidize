from fastapi.responses import JSONResponse

from src.models import ErrorResponse
from src.core.exceptions import HashServiceError


async def hash_service_error_handler(_, exc: HashServiceError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            message=exc.detail, type=exc.__class__.__name__.lower(), details=exc.details
        ).dict(),
    )


def register_exception_handlers(app):
    app.add_exception_handler(HashServiceError, hash_service_error_handler)
