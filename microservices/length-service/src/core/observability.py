import os
import time
from fastapi import FastAPI, Request
from prometheus_client import Counter, Histogram, make_asgi_app
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from src.config import get_settings

REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["method", "endpoint"])
REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "Histogram of HTTP request durations",
    ["method", "endpoint"],
)
ERRORS = Counter(
    "http_errors_total",
    "Total HTTP error responses",
    ["method", "endpoint", "status_code"],
)


def setup_observability(app: FastAPI):
    if os.getenv("DISABLE_OTEL", "false").lower() == "true":
        return

    settings = get_settings()

    trace.set_tracer_provider(
        TracerProvider(resource=Resource.create({"service.name": settings.app_name}))
    )

    endpoint = f"http://{settings.otlp_host}:{settings.otlp_port}"

    span_processor = BatchSpanProcessor(
        OTLPSpanExporter(
            endpoint=endpoint,
            insecure=True,
        )
    )

    trace.get_tracer_provider().add_span_processor(span_processor)

    FastAPIInstrumentor.instrument_app(app, tracer_provider=trace.get_tracer_provider())

    app.mount("/metrics", make_asgi_app())

    @app.middleware("http")
    async def track_requests_and_errors(request: Request, call_next):
        start_time = time.time()

        tracer = trace.get_tracer(__name__)
        with tracer.start_as_current_span("http-request"):
            response = await call_next(request)

        REQUESTS.labels(method=request.method, endpoint=request.url.path).inc()

        process_time = time.time() - start_time
        REQUEST_DURATION.labels(
            method=request.method, endpoint=request.url.path
        ).observe(process_time)

        if response.status_code >= 400:
            ERRORS.labels(
                method=request.method,
                endpoint=request.url.path,
                status_code=str(response.status_code),
            ).inc()

        return response
