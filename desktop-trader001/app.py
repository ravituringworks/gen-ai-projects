from flask import Flask, render_template, request, jsonify
import api_client

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/search')
def search():
    query = request.args.get('query')
    if not query:
        return jsonify([])
    try:
        results = api_client.search_symbol(query)
        print(results)
        return jsonify(results)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chart')
def chart():
    symbol = request.args.get('symbol')
    time_range = request.args.get('range', '1D')

    if not symbol:
        return jsonify({})

    try:
        if time_range == '1D':
            data = api_client.get_intraday_time_series(symbol, '5min')
        elif time_range == '5D':
            data = api_client.get_intraday_time_series(symbol, '60min')
        else:
            data = api_client.get_daily_time_series(symbol)
        return jsonify(data)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
