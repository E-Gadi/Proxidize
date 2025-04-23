def test_length_endpoint(client):
    response = client.post("/length/", json={"input_string": "test"})
    assert response.status_code == 200
    assert response.json()["length"] == 4


def test_length_empty_input(client):
    response = client.post("/length/", json={"input_string": ""})
    assert response.status_code == 400
    assert response.json()["type"] == "invalidinputerror"


def test_health_check(client):
    """Test health check endpoint"""
    response = client.get("/health/")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
