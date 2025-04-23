def test_hash_endpoint(client):
    response = client.post("/hash/", json={"input_string": "test"})
    assert response.status_code == 200
    assert len(response.json()["hash"]) == 64


def test_hash_empty_input(client):
    response = client.post("/hash/", json={"input_string": ""})
    assert response.status_code == 400
    assert response.json()["type"] == "invalidinputerror"


def test_health_check(client):
    """Test health check endpoint"""
    response = client.get("/health/")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
