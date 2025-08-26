import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

def create_chart(parent, data):
    fig, ax = plt.subplots()
    dates = list(data.keys())
    prices = [float(item['4. close']) for item in data.values()]
    ax.plot(dates, prices)
    ax.xaxis.set_major_locator(plt.MaxNLocator(10)) # Limit number of x-axis labels
    plt.xticks(rotation=45)
    plt.tight_layout()

    canvas = FigureCanvasTkAgg(fig, master=parent)
    canvas.draw()
    return canvas.get_tk_widget()
