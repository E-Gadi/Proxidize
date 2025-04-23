from typing import Annotated
from opentelemetry.trace import Tracer, get_tracer as otel_get_tracer
from fastapi import Depends


def provide_tracer() -> Tracer:
    return otel_get_tracer("hash-service")

TracerDep = Annotated[Tracer, Depends(provide_tracer)]