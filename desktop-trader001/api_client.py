import configparser
import requests

def get_api_key():
    config = configparser.ConfigParser()
    config.read('/Users/ravindraboddipalli/sources/python/desktop-trader/config.ini')
    return config['alpha_vantage']['api_key']

API_URL = "https://www.alphavantage.co/query"

def search_symbol(keywords):
    params = {
        "function": "SYMBOL_SEARCH",
        "keywords": keywords,
        "apikey": get_api_key()
    }
    response = requests.get(API_URL, params=params)
    response.raise_for_status()
    return response.json().get('bestMatches', [])

def get_daily_time_series(symbol, outputsize='full'):
    params = {
        "function": "TIME_SERIES_DAILY",
        "symbol": symbol,
        "outputsize": outputsize,
        "apikey": get_api_key()
    }
    response = requests.get(API_URL, params=params)
    response.raise_for_status()
    return response.json().get('Time Series (Daily)', {})

def get_intraday_time_series(symbol, interval='5min', outputsize='full'):
    params = {
        "function": "TIME_SERIES_INTRADAY",
        "symbol": symbol,
        "interval": interval,
        "outputsize": outputsize,
        "apikey": get_api_key()
    }
    response = requests.get(API_URL, params=params)
    response.raise_for_status()
    return response.json().get(f'Time Series ({interval})', {})
