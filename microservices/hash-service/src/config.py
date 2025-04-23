from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_version: str = "1.0.0"
    app_name: str = "hash-service"
    otlp_host: str = "jaeger-collector.default.svc.cluster.local"
    otlp_port: int = 4317

    class Config:
        env_prefix = ''
        env_file = '.env'

@lru_cache()
def get_settings() -> Settings:
    return Settings()
