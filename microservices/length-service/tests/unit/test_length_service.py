import pytest
from src.services.length_service import compute_length
from src.core.exceptions import InvalidInputError, LengthComputationError


def test_compute_length():
    """Test length computation"""
    result = compute_length("test")
    assert result == 4


def test_compute_length_empty_input():
    """Test empty input validation"""
    with pytest.raises(InvalidInputError):
        compute_length("")


def test_compute_length_invalid_input():
    """Test invalid input type"""
    with pytest.raises(LengthComputationError):
        compute_length(123)
