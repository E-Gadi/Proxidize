from src.core.exceptions import InvalidInputError, LengthComputationError


def compute_length(input_string: str) -> int:
    """Compute the length of the input string"""
    if not input_string:
        raise InvalidInputError("Input string cannot be empty")

    try:
        return len(input_string)
    except Exception as e:
        raise LengthComputationError(
            detail="Failed to compute length", details={"error": str(e)}
        )
