"""
Demo App — Agentic Dev Kit 端到端演示用示例应用
"""
from fastapi import FastAPI

app = FastAPI(title="Demo App", version="1.0.0")


@app.get("/")
def root():
    """首页"""
    return {"message": "Hello, Agentic Dev Kit!"}


@app.get("/health")
def health():
    """健康检查接口"""
    return {"status": "ok", "version": "1.0.0"}


@app.get("/api/users")
def list_users():
    """用户列表（示例）"""
    return {
        "users": [
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"},
        ]
    }
