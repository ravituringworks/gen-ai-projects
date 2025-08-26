

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI, Request, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional, List, Dict, Any
import random
import asyncio
import datetime
from authlib.integrations.starlette_client import OAuth
from sqlalchemy.orm import Session

from database import SessionLocal, engine
import models, schemas

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# Dependency to get the database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Configure CORS
origins = [
    "http://localhost:5173",  # React frontend
    "http://127.0.0.1:5173",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Google OAuth Configuration
# IMPORTANT: Replace with your actual Client ID and Client Secret
# For development, you can put them directly here, but for production,
# use environment variables.
GOOGLE_CLIENT_ID = "YOUR_GOOGLE_CLIENT_ID"
GOOGLE_CLIENT_SECRET = "YOUR_GOOGLE_CLIENT_SECRET"

# Initialize OAuth
oauth = OAuth()
oauth.register(
    name='google',
    client_id=GOOGLE_CLIENT_ID,
    client_secret=GOOGLE_CLIENT_SECRET,
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

# WebSocket Connection Manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.get("/api/hello")
async def read_root():
    return {"message": "Hello from FastAPI!"}

# Watchlist Endpoints
@app.get("/api/watchlist", response_model=List[schemas.WatchlistItem])
async def get_watchlist(db: Session = Depends(get_db)):
    watchlist = db.query(models.WatchlistItem).all()
    return watchlist

@app.post("/api/watchlist", response_model=schemas.WatchlistItem)
async def create_watchlist_item(item: schemas.WatchlistItemCreate, db: Session = Depends(get_db)):
    db_item = models.WatchlistItem(symbol=item.symbol, price=item.price, change=item.change, changePercent=item.changePercent)
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

@app.delete("/api/watchlist/{symbol}")
async def delete_watchlist_item(symbol: str, db: Session = Depends(get_db)):
    db_item = db.query(models.WatchlistItem).filter(models.WatchlistItem.symbol == symbol).first()
    if db_item is None:
        raise HTTPException(status_code=404, detail="Watchlist item not found")
    db.delete(db_item)
    db.commit()
    return {"message": f"Watchlist item {symbol} deleted"}

@app.get("/api/chart-data")
async def get_chart_data(chart_type: Optional[str] = "line"):
    data = []
    if chart_type == "candlestick":
        # Generate mock candlestick data (OHLC)
        base_price = 100
        for i in range(7):
            open_price = round(base_price + random.uniform(-2, 2), 2)
            close_price = round(open_price + random.uniform(-5, 5), 2)
            high_price = round(max(open_price, close_price) + random.uniform(0, 3), 2)
            low_price = round(min(open_price, close_price) - random.uniform(0, 3), 2)
            data.append({
                "name": f"Day {i+1}",
                "open": open_price,
                "close": close_price,
                "high": high_price,
                "low": low_price,
            })
            base_price = close_price # Next day's price starts near current day's close
    else:
        # Generate mock line/bar data with a simple moving average
        prices = [random.randint(100, 200) for _ in range(7)]
        ma_period = 3 # Simple 3-period moving average
        for i in range(len(prices)):
            ma = None
            if i >= ma_period - 1:
                ma = sum(prices[i-ma_period+1:i+1]) / ma_period
            data.append({
                "name": f"Day {i+1}",
                "price": prices[i],
                "ma": ma,
            })
    return data

# Order Endpoints
@app.get("/api/orders", response_model=List[schemas.Order])
async def get_orders(db: Session = Depends(get_db)):
    orders = db.query(models.Order).all()
    return orders

@app.post("/api/orders", response_model=schemas.Order)
async def create_order(order: schemas.OrderCreate, db: Session = Depends(get_db)):
    db_order = models.Order(id=str(random.randint(10000, 99999)), **order.model_dump())
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    return db_order

@app.delete("/api/orders/{order_id}")
async def cancel_order(order_id: str, db: Session = Depends(get_db)):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    db.delete(db_order)
    db.commit()
    return {"message": f"Order {order_id} cancelled"}

@app.put("/api/orders/{order_id}", response_model=schemas.Order)
async def edit_order(order_id: str, updated_order: schemas.OrderUpdate, db: Session = Depends(get_db)):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    for key, value in updated_order.model_dump(exclude_unset=True).items():
        setattr(db_order, key, value)
    db.commit()
    db.refresh(db_order)
    return db_order

# Portfolio Endpoints
@app.get("/api/portfolio", response_model=List[schemas.PortfolioHolding])
async def get_portfolio(db: Session = Depends(get_db)):
    portfolio = db.query(models.PortfolioHolding).all()
    return portfolio

@app.post("/api/portfolio", response_model=schemas.PortfolioHolding)
async def create_portfolio_holding(holding: schemas.PortfolioHoldingCreate, db: Session = Depends(get_db)):
    db_holding = models.PortfolioHolding(**holding.model_dump())
    db.add(db_holding)
    db.commit()
    db.refresh(db_holding)
    return db_holding

@app.put("/api/portfolio/{symbol}", response_model=schemas.PortfolioHolding)
async def update_portfolio_holding(symbol: str, updated_holding: schemas.PortfolioHoldingCreate, db: Session = Depends(get_db)):
    db_holding = db.query(models.PortfolioHolding).filter(models.PortfolioHolding.symbol == symbol).first()
    if db_holding is None:
        raise HTTPException(status_code=404, detail="Portfolio holding not found")
    for key, value in updated_holding.model_dump(exclude_unset=True).items():
        setattr(db_holding, key, value)
    db.commit()
    db.refresh(db_holding)
    return db_holding

@app.delete("/api/portfolio/{symbol}")
async def delete_portfolio_holding(symbol: str, db: Session = Depends(get_db)):
    db_holding = db.query(models.PortfolioHolding).filter(models.PortfolioHolding.symbol == symbol).first()
    if db_holding is None:
        raise HTTPException(status_code=404, detail="Portfolio holding not found")
    db.delete(db_holding)
    db.commit()
    return {"message": f"Portfolio holding {symbol} deleted"}

@app.get("/login/google")
async def login_google(request: Request):
    redirect_uri = request.url_for('auth_google')
    return await oauth.google.authorize_redirect(request, redirect_uri)

@app.get("/auth/google")
async def auth_google(request: Request):
    token = await oauth.google.authorize_access_token(request)
    user = await oauth.google.parse_id_token(request, token)
    # In a real application, you would store user information in a session or database
    # For now, we'll just return the user info.
    return user

@app.websocket("/ws/prices")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # In a real application, you would fetch real-time data here
            # For now, send mock updates for existing watchlist items
            db = SessionLocal() # Get a new session for the background task
            watchlist_items = db.query(models.WatchlistItem).all()
            db.close()

            for item in watchlist_items:
                new_price = round(item.price + random.uniform(-1, 1), 2)
                change = round(new_price - item.price, 2)
                change_percent = round((change / item.price) * 100, 2) if item.price != 0 else 0

                # Update the database with new prices
                db = SessionLocal()
                db_item = db.query(models.WatchlistItem).filter(models.WatchlistItem.symbol == item.symbol).first()
                if db_item:
                    db_item.price = new_price
                    db_item.change = change
                    db_item.changePercent = change_percent
                    db.commit()
                    db.refresh(db_item)
                db.close()

                await manager.broadcast(f"{{\"symbol\": \"{item.symbol}\", \"price\": {new_price}, \"change\": {change}, \"changePercent\": {change_percent}}}")
            await asyncio.sleep(2) # Send updates every 2 seconds
    except WebSocketDisconnect:
        manager.disconnect(websocket)
