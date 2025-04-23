import hashlib
from src.core.exceptions import InvalidInputError, HashComputationError


def compute_hash(input_string: str) -> str:
    """Compute SHA256 hash of input string"""
    if not input_string:
        raise InvalidInputError("Input string cannot be empty")

    try:
        return hashlib.sha256(input_string.encode()).hexdigest()
    except Exception as e:
        raise HashComputationError(
            detail="Failed to compute hash", details={"error": str(e)}
        )
