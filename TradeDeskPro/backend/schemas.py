from pydantic import BaseModel, ConfigDict
from typing import Optional, List
import datetime

class WatchlistItemBase(BaseModel):
    symbol: str
    price: float
    change: float
    changePercent: float

class WatchlistItemCreate(WatchlistItemBase):
    pass

class WatchlistItem(WatchlistItemBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

class OrderBase(BaseModel):
    symbol: str
    type: str
    quantity: int
    price: float
    status: str

class OrderCreate(OrderBase):
    pass

class OrderUpdate(BaseModel):
    quantity: Optional[int] = None
    price: Optional[float] = None
    status: Optional[str] = None

class Order(OrderBase):
    id: str
    timestamp: datetime.datetime

    model_config = ConfigDict(from_attributes=True)

class PortfolioHoldingBase(BaseModel):
    symbol: str
    quantity: int
    avgPrice: float
    currentPrice: float

class PortfolioHoldingCreate(PortfolioHoldingBase):
    pass

class PortfolioHolding(PortfolioHoldingBase):
    id: int

    model_config = ConfigDict(from_attributes=True)