# MASTER DESIGN BIBLE

## Vision
Build an institutional-grade, modular quantitative trading engine.

## Objectives
- Win rate target: 70-80%
- 8-12 trades/day
- M15 execution
- Multi-symbol (Forex + Gold) — via multiple independent symbol-scoped runtime instances, one per symbol, not a single runtime spanning multiple symbols (ADR-001)

## Confirmed Philosophy
- Evidence-based trading
- Modular architecture
- No indicator stacking
- Context first, execution second

## Current Roadmap
1. Architecture
2. Market Regime
3. HTF Bias
4. Liquidity
5. OB/FVG
6. Sessions
7. Trade Quality Index
8. Execution
9. Risk
10. Learning
11. Dashboard
12. Final Review