document.addEventListener('DOMContentLoaded', () => {
    const searchInput = document.getElementById('search-input');
    const searchButton = document.getElementById('search-button');
    const searchResults = document.getElementById('search-results');
    const watchlist = document.getElementById('watchlist');
    const chartCanvas = document.getElementById('chart');
    const timeRangeButtons = document.querySelectorAll('.time-range-btn');
    let chart;
    let currentSymbol;

    searchButton.addEventListener('click', async () => {
        const query = searchInput.value;
        if (!query) return;

        const response = await fetch(`/search?query=${query}`);
        const data = await response.json();

        searchResults.innerHTML = '';
        if (data.bestMatches) {
            data.bestMatches.forEach(result => {
                const div = document.createElement('div');
                div.textContent = `${result['1. symbol']} - ${result['2. name']}`;
                div.style.cursor = 'pointer';
                div.addEventListener('click', () => {
                    addToWatchlist(result['1. symbol'], result['2. name']);
                    searchResults.innerHTML = '';
                });
                searchResults.appendChild(div);
            });
        }
    });

    function addToWatchlist(symbol, name) {
        if (document.querySelector(`li[data-symbol='${symbol}']`)) return;

        const li = document.createElement('li');
        li.textContent = `${symbol} - ${name}`;
        li.dataset.symbol = symbol;
        li.addEventListener('click', () => {
            currentSymbol = symbol;
            displayChart(currentSymbol, '1D');
        });
        watchlist.appendChild(li);
    }

    timeRangeButtons.forEach(button => {
        button.addEventListener('click', () => {
            if (currentSymbol) {
                const range = button.dataset.range;
                displayChart(currentSymbol, range);
            }
        });
    });

    async function displayChart(symbol, range) {
        const response = await fetch(`/chart?symbol=${symbol}&range=${range}`);
        const data = await response.json();

        if (chart) {
            chart.destroy();
        }

        let chartData = Object.keys(data).map(date => ({
            x: new Date(date),
            o: parseFloat(data[date]['1. open']),
            h: parseFloat(data[date]['2. high']),
            l: parseFloat(data[date]['3. low']),
            c: parseFloat(data[date]['4. close'])
        }));

        // Filter data for longer ranges
        const now = new Date();
        let startDate;
        if (range === '1M') {
            startDate = new Date(new Date().setMonth(now.getMonth() - 1));
        } else if (range === '6M') {
            startDate = new Date(new Date().setMonth(now.getMonth() - 6));
        } else if (range === '1Y') {
            startDate = new Date(new Date().setFullYear(now.getFullYear() - 1));
        }

        if (startDate) {
            chartData = chartData.filter(item => item.x >= startDate);
        }

        chart = new Chart(chartCanvas, {
            type: 'candlestick',
            data: {
                datasets: [{
                    label: symbol,
                    data: chartData,
                }]
            },
            options: {
                scales: {
                    x: {
                        adapters: {
                            date: {
                                locale: 'en-US'
                            }
                        }
                    }
                }
            }
        });
    }
});
