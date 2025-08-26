from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import pytest

from main import app, get_db
from database import Base
from schemas import OrderUpdate # Import the new schema

# Use an in-memory SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(name="db_session")
def db_session_fixture():
    Base.metadata.create_all(bind=engine)  # Create tables
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)  # Drop tables after test


@pytest.fixture(name="client")
def client_fixture(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def test_read_main(client):
    response = client.get("/api/hello")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello from FastAPI!"}

def test_create_watchlist_item(client):
    response = client.post(
        "/api/watchlist",
        json={
            "symbol": "TEST_WL",
            "price": 100.0,
            "change": 1.0,
            "changePercent": 1.0
        },
    )
    assert response.status_code == 200
    assert response.json()["symbol"] == "TEST_WL"

def test_get_watchlist(client):
    client.post(
        "/api/watchlist",
        json={
            "symbol": "GET_WL",
            "price": 100.0,
            "change": 1.0,
            "changePercent": 1.0
        },
    )
    response = client.get("/api/watchlist")
    assert response.status_code == 200
    assert len(response.json()) > 0

def test_delete_watchlist_item(client):
    client.post(
        "/api/watchlist",
        json={
            "symbol": "DELETE_ME_WL",
            "price": 10.0,
            "change": 0.1,
            "changePercent": 0.1
        },
    )
    response = client.delete("/api/watchlist/DELETE_ME_WL")
    assert response.status_code == 200
    assert response.json() == {"message": "Watchlist item DELETE_ME_WL deleted"}

def test_create_order(client):
    response = client.post(
        "/api/orders",
        json={
            "symbol": "TEST_ORDER",
            "type": "BUY",
            "quantity": 5,
            "price": 50.0,
            "status": "Pending"
        },
    )
    assert response.status_code == 200
    assert response.json()["symbol"] == "TEST_ORDER"

def test_get_orders(client):
    client.post(
        "/api/orders",
        json={
            "symbol": "GET_ORDER",
            "type": "SELL",
            "quantity": 1,
            "price": 10.0,
            "status": "Filled"
        },
    )
    response = client.get("/api/orders")
    assert response.status_code == 200
    assert len(response.json()) > 0

def test_edit_order(client):
    create_response = client.post(
        "/api/orders",
        json={
            "symbol": "EDIT_ME_ORDER",
            "type": "BUY",
            "quantity": 10,
            "price": 100.0,
            "status": "Pending"
        },
    )
    order_id = create_response.json()["id"]

    # Use OrderUpdate schema fields
    response = client.put(
        f"/api/orders/{order_id}",
        json={
            "quantity": 15,
            "price": 105.0,
            "status": "Pending" # Include status as it's part of OrderUpdate
        },
    )
    assert response.status_code == 200
    assert response.json()["quantity"] == 15
    assert response.json()["price"] == 105.0
    assert response.json()["status"] == "Pending"

def test_cancel_order(client):
    create_response = client.post(
        "/api/orders",
        json={
            "symbol": "CANCEL_ME_ORDER",
            "type": "SELL",
            "quantity": 1,
            "price": 10.0,
            "status": "Pending"
        },
    )
    order_id = create_response.json()["id"]

    response = client.delete(f"/api/orders/{order_id}")
    assert response.status_code == 200
    assert response.json() == {"message": f"Order {order_id} cancelled"}

def test_create_portfolio_holding(client):
    response = client.post(
        "/api/portfolio",
        json={
            "symbol": "TEST_HOLDING",
            "quantity": 10,
            "avgPrice": 200.0,
            "currentPrice": 205.0
        },
    )
    assert response.status_code == 200
    assert response.json()["symbol"] == "TEST_HOLDING"

def test_get_portfolio(client):
    client.post(
        "/api/portfolio",
        json={
            "symbol": "GET_HOLDING",
            "quantity": 1,
            "avgPrice": 10.0,
            "currentPrice": 11.0
        },
    )
    response = client.get("/api/portfolio")
    assert response.status_code == 200
    assert len(response.json()) > 0

def test_update_portfolio_holding(client):
    client.post(
        "/api/portfolio",
        json={
            "symbol": "UPDATE_ME_HOLDING",
            "quantity": 5,
            "avgPrice": 50.0,
            "currentPrice": 55.0
        },
    )
    response = client.put(
        "/api/portfolio/UPDATE_ME_HOLDING",
        json={
            "symbol": "UPDATE_ME_HOLDING",
            "quantity": 7,
            "avgPrice": 52.0,
            "currentPrice": 58.0
        },
    )
    assert response.status_code == 200
    assert response.json()["quantity"] == 7
    assert response.json()["avgPrice"] == 52.0

def test_delete_portfolio_holding(client):
    client.post(
        "/api/portfolio",
        json={
            "symbol": "DELETE_HOLDING",
            "quantity": 1,
            "avgPrice": 1.0,
            "currentPrice": 1.0
        },
    )
    response = client.delete("/api/portfolio/DELETE_HOLDING")
    assert response.status_code == 200
    assert response.json() == {"message": "Portfolio holding DELETE_HOLDING deleted"}