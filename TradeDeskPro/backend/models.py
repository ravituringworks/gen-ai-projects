from sqlalchemy import Column, Integer, String, Float, DateTime
from database import Base # Changed from relative to absolute import
import datetime

class WatchlistItem(Base):
    __tablename__ = "watchlist_items"

    id = Column(Integer, primary_key=True, index=True)
    symbol = Column(String, unique=True, index=True)
    price = Column(Float)
    change = Column(Float)
    changePercent = Column(Float)

class Order(Base):
    __tablename__ = "orders"

    id = Column(String, primary_key=True, index=True)
    symbol = Column(String, index=True)
    type = Column(String)
    quantity = Column(Integer)
    price = Column(Float)
    status = Column(String)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class PortfolioHolding(Base):
    __tablename__ = "portfolio_holdings"

    id = Column(Integer, primary_key=True, index=True)
    symbol = Column(String, unique=True, index=True)
    quantity = Column(Integer)
    avgPrice = Column(Float)
    currentPrice = Column(Float)