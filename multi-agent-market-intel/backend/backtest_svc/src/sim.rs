use crate::model::*;

pub struct EngineCfg { pub rebalance_days: i64, pub tc_bps: f64, pub borrow_bps: f64 }

pub fn simulate(mut nav: f64, targets: &[DailyTarget], bars: &std::collections::HashMap<String, Vec<Bar>>, cfg: &EngineCfg) -> Report {
    use uuid::Uuid;
    let run_id = Uuid::new_v4();
    let mut curve = Vec::new();
    let mut holdings: std::collections::HashMap<String, f64> = Default::default();
    let mut last_reb = None;
    let mut peak = nav; let mut max_dd = 0.0; let mut turnover_acc = 0.0;

    for tgt in targets {
        if last_reb.map(|d| (tgt.ts - d).num_days() >= cfg.rebalance_days).unwrap_or(true) {
            let mut desired: std::collections::HashMap<String, f64> = Default::default();
            for (sym, w) in &tgt.weights { desired.insert(sym.clone(), w * nav); }
            for (sym, d_amt) in desired.iter() {
                let px = util::close_on(sym, tgt.ts, bars).unwrap_or(100.0);
                let cur_qty = *holdings.get(sym).unwrap_or(&0.0);
                let cur_val = cur_qty * px;
                let delta_val = d_amt - cur_val;
                let dq = delta_val / px;
                let tc = (cfg.tc_bps / 10_000.0) * delta_val.abs();
                nav -= tc; turnover_acc += delta_val.abs();
                *holdings.entry(sym.clone()).or_insert(0.0) += dq;
            }
            last_reb = Some(tgt.ts);
        }
        let mut total = 0.0;
        for (sym, q) in holdings.iter() {
            let px = util::close_on(sym, tgt.ts, bars).unwrap_or(100.0);
            total += q * px;
        }
        nav = total;
        curve.push(EquityPoint{ ts: tgt.ts, nav });
        peak = peak.max(nav);
        max_dd = max_dd.min((nav/peak) - 1.0);
    }
    let r = curve.windows(2).map(|w| (w[1].nav/w[0].nav)-1.0).collect::<Vec<f64>>();
    let mean = if r.is_empty(){0.0}else{ r.iter().sum::<f64>()/(r.len() as f64)};
    let var = if r.len()<2{0.0}else{ let m=mean; r.iter().map(|x| (x-m)*(x-m)).sum::<f64>()/((r.len()-1) as f64)};
    let sharpe = if var==0.0 {0.0} else { (mean*252.0)/((var.sqrt()) * (252.0f64).sqrt()) };
    let turnover = turnover_acc.max(1.0);
    Report{ run_id, sharpe, max_dd, turnover, equity_curve: curve }
}

pub mod util{
    use super::*;
    pub fn close_on(sym: &str, day: chrono::DateTime<chrono::Utc>, bars: &std::collections::HashMap<String, Vec<Bar>>) -> Option<f64> {
        bars.get(sym).and_then(|v| v.iter().find(|b| b.ts.date_naive()==day.date_naive()).map(|b| b.close))
    }
}
