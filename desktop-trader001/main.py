import customtkinter as ctk
from tkinter import messagebox
import api_client
import charting

class StockTraderApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Desktop Trader")
        self.geometry("1200x800")

        # Main frame
        main_frame = ctk.CTkFrame(self)
        main_frame.pack(fill=ctk.BOTH, expand=True, padx=10, pady=10)

        # Left panel (watchlist and search)
        left_panel = ctk.CTkFrame(main_frame)
        left_panel.pack(side=ctk.LEFT, fill=ctk.Y, padx=(0, 5))

        # Search frame
        search_frame = ctk.CTkFrame(left_panel)
        search_frame.pack(pady=10, padx=10, fill=ctk.X)

        self.search_entry = ctk.CTkEntry(search_frame, placeholder_text="Search for a stock...")
        self.search_entry.pack(side=ctk.LEFT, fill=ctk.X, expand=True)
        self.search_entry.bind("<Return>", self.search_stock)

        self.search_button = ctk.CTkButton(search_frame, text="Search", command=self.search_stock)
        self.search_button.pack(side=ctk.LEFT, padx=(5, 0))

        # Watchlist frame
        self.watchlist_frame = ctk.CTkFrame(left_panel)
        self.watchlist_frame.pack(pady=10, padx=10, fill=ctk.BOTH, expand=True)

        self.watchlist_label = ctk.CTkLabel(self.watchlist_frame, text="Watchlist")
        self.watchlist_label.pack()

        self.watchlist = {}

        # Right panel (chart)
        self.chart_frame = ctk.CTkFrame(main_frame)
        self.chart_frame.pack(side=ctk.LEFT, fill=ctk.BOTH, expand=True, padx=(5, 0))

        self.chart_label = ctk.CTkLabel(self.chart_frame, text="Stock Chart")
        self.chart_label.pack()

        self.current_chart = None

    def search_stock(self, event=None):
        query = self.search_entry.get()
        if not query:
            return

        try:
            results = api_client.search_symbol(query)
            if not results:
                messagebox.showinfo("Search Results", "No results found.")
                return

            # For simplicity, we'll just add the first result to the watchlist
            first_result = results[0]
            symbol = first_result['1. symbol']
            name = first_result['2. name']
            self.add_to_watchlist(symbol, name)

        except Exception as e:
            messagebox.showerror("Error", f"Failed to search for stock: {e}")

    def add_to_watchlist(self, symbol, name):
        if symbol in self.watchlist:
            return

        self.watchlist[symbol] = name
        btn = ctk.CTkButton(self.watchlist_frame, text=f"{symbol} - {name}", command=lambda s=symbol: self.display_chart(s))
        btn.pack(fill=ctk.X, pady=2)

    def display_chart(self, symbol):
        try:
            data = api_client.get_daily_time_series(symbol)
            if not data:
                messagebox.showinfo("Chart Data", "No chart data available for this stock.")
                return

            if self.current_chart:
                self.current_chart.destroy()

            self.current_chart = charting.create_chart(self.chart_frame, data)
            self.current_chart.pack(fill=ctk.BOTH, expand=True)

        except Exception as e:
            messagebox.showerror("Error", f"Failed to get chart data: {e}")

if __name__ == "__main__":
    app = StockTraderApp()
    app.mainloop()
