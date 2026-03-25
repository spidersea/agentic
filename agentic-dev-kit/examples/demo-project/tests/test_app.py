"""
Demo App — 测试用例
"""
from fastapi.testclient import TestClient
from src.app import app

client = TestClient(app)


def test_root():
    """测试首页"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == "Hello, Agentic Dev Kit!"


def test_health():
    """测试健康检查"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_list_users():
    """测试用户列表"""
    response = client.get("/api/users")
    assert response.status_code == 200
    assert len(response.json()["users"]) == 2
