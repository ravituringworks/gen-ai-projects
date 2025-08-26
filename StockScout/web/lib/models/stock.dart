class Stock {
  final String id;
  final String symbol;
  final String name;
  final String exchange;
  final double? marketCap;
  final double? price;
  final int? volume;
  final String? sector;
  final DateTime createdAt;
  final DateTime updatedAt;

  Stock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.exchange,
    this.marketCap,
    this.price,
    this.volume,
    this.sector,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'] ?? '',
      marketCap: _parseDouble(json['market_cap']),
      price: _parseDouble(json['price']),
      volume: _parseInt(json['volume']),
      sector: json['sector'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get formattedMarketCap {
    if (marketCap == null) return 'N/A';
    if (marketCap! >= 1e12) return '\$${(marketCap! / 1e12).toStringAsFixed(1)}T';
    if (marketCap! >= 1e9) return '\$${(marketCap! / 1e9).toStringAsFixed(1)}B';
    if (marketCap! >= 1e6) return '\$${(marketCap! / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap!.toStringAsFixed(0)}';
  }

  String get formattedPrice {
    if (price == null) return 'N/A';
    return '\$${price!.toStringAsFixed(2)}';
  }

  String get formattedVolume {
    if (volume == null) return 'N/A';
    if (volume! >= 1e9) return '${(volume! / 1e9).toStringAsFixed(1)}B';
    if (volume! >= 1e6) return '${(volume! / 1e6).toStringAsFixed(1)}M';
    if (volume! >= 1e3) return '${(volume! / 1e3).toStringAsFixed(1)}K';
    return volume!.toString();
  }
}

class TopStock {
  final String symbol;
  final String name;
  final String exchange;
  final double? price;
  final double? marketCap;
  final double score;
  final String reasoning;

  TopStock({
    required this.symbol,
    required this.name,
    required this.exchange,
    this.price,
    this.marketCap,
    required this.score,
    required this.reasoning,
  });

  factory TopStock.fromJson(Map<String, dynamic> json) {
    return TopStock(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'] ?? '',
      price: Stock._parseDouble(json['price']),
      marketCap: Stock._parseDouble(json['market_cap']),
      score: Stock._parseDouble(json['score']) ?? 0.0,
      reasoning: json['reasoning'] ?? '',
    );
  }

  String get formattedScore => '${(score * 100).toStringAsFixed(1)}%';
  
  String get formattedPrice => price != null ? '\$${price!.toStringAsFixed(2)}' : 'N/A';
  
  String get formattedMarketCap {
    if (marketCap == null) return 'N/A';
    if (marketCap! >= 1e12) return '\$${(marketCap! / 1e12).toStringAsFixed(1)}T';
    if (marketCap! >= 1e9) return '\$${(marketCap! / 1e9).toStringAsFixed(1)}B';
    if (marketCap! >= 1e6) return '\$${(marketCap! / 1e6).toStringAsFixed(1)}M';
    return '\$${marketCap!.toStringAsFixed(0)}';
  }
}
