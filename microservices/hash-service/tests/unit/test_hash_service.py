import pytest
from src.services.hash_service import compute_hash
from src.core.exceptions import InvalidInputError, HashComputationError


def test_compute_hash():
    """Test hash computation"""
    result = compute_hash("test")
    assert len(result) == 64
    assert result == "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"


def test_compute_hash_empty_input():
    """Test empty input validation"""
    with pytest.raises(InvalidInputError):
        compute_hash("")


def test_compute_hash_invalid_input():
    with pytest.raises(HashComputationError):
        compute_hash(123)
