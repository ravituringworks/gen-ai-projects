#[derive(Clone)]
pub struct ScreeningService;

impl ScreeningService {
    pub fn new() -> Self {
        Self
    }
    
    pub fn calculate_momentum_score(&self, market_cap: f64, volume: Option<i64>) -> f64 {
        let mut score: f64 = 0.0;
        
        // Volume momentum (higher volume = higher momentum)
        if let Some(vol) = volume {
            score += (vol as f64 / 10_000_000.0).min(0.3);
        }
        
        // Market cap factor for momentum (mid-cap premium)
        if market_cap > 500_000_000.0 && market_cap < 10_000_000_000.0 {
            score += 0.2;
        }
        
        // Volatility boost for short-term trades
        score += 0.1;
        
        score.min(1.0)
    }
    
    pub fn calculate_growth_score(&self, market_cap: f64) -> f64 {
        let mut score: f64 = 0.0;
        
        // Growth scoring based on market cap categories
        if market_cap < 300_000_000.0 {
            score += 0.4; // Small cap growth premium
        } else if market_cap < 2_000_000_000.0 {
            score += 0.3; // Mid cap growth
        } else if market_cap < 10_000_000_000.0 {
            score += 0.2; // Large cap stability
        } else {
            score += 0.1; // Mega cap limited growth
        }
        
        // Add random factor for growth potential
        score += rand::random::<f64>() * 0.3;
        
        score.min(1.0)
    }
    
    pub fn calculate_value_score(&self, market_cap: f64, price: Option<f64>) -> f64 {
        let mut score: f64 = 0.0;
        
        // Value scoring (inverse relationship with price for simplicity)
        if let Some(p) = price {
            if p < 50.0 {
                score += 0.3;
            } else if p < 200.0 {
                score += 0.2;
            } else {
                score += 0.1;
            }
        }
        
        // Market cap value factor
        if market_cap > 1_000_000_000.0 && market_cap < 50_000_000_000.0 {
            score += 0.2; // Established companies with room to grow
        }
        
        // Long-term stability factor
        score += 0.2;
        
        score.min(1.0)
    }
    
    pub fn calculate_volume_score(&self, volume: f64) -> f64 {
        // Logarithmic scaling for volume
        let normalized_volume = (volume / 1_000_000.0).ln().max(0.0);
        (normalized_volume / 10.0).min(0.2)
    }
    
    pub fn calculate_sector_score(&self, sector: &str) -> f64 {
        match sector {
            "Technology" => 0.25,
            "Healthcare" => 0.20,
            "Consumer Discretionary" => 0.15,
            "Financial Services" => 0.10,
            "Communication Services" => 0.10,
            "Industrials" => 0.08,
            "Consumer Staples" => 0.05,
            "Energy" => 0.05,
            "Materials" => 0.05,
            "Real Estate" => 0.03,
            "Utilities" => 0.02,
            _ => 0.0,
        }
    }
    
    pub fn apply_risk_adjustment(&self, base_score: f64, market_cap: f64) -> f64 {
        let risk_factor = if market_cap < 300_000_000.0 {
            0.8 // Higher risk for small caps
        } else if market_cap < 2_000_000_000.0 {
            0.9 // Moderate risk for mid caps
        } else {
            1.0 // Lower risk for large caps
        };
        
        base_score * risk_factor
    }
}
