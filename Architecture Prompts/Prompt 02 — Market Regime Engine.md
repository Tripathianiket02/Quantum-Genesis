PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 02

Market Regime Engine

==================================================================

OBJECTIVE

Design and implement a fully modular Market Regime Engine in MQL5.

This module must NOT generate trading signals.

Its sole responsibility is to classify the current market environment
using objective statistical measurements.

The output of this engine will later become one component of the
overall Trade Quality Index.

This module must be completely independent from Liquidity,
Order Blocks, FVGs, Entries, and Risk Management.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle:
The Regime Engine only classifies market regimes.

Do not execute trades.

Do not calculate entries.

Do not manage positions.

Do not calculate liquidity.

Do not detect order blocks.

Keep the module completely isolated.

==================================================================

DESIGN GOALS

The engine must classify the market into one of the following
institutional regimes.

UNKNOWN

TRENDING_BULL

TRENDING_BEAR

PULLBACK

RANGING

COMPRESSION

EXPANSION

HIGH_VOLATILITY

LOW_VOLATILITY

TRANSITION

NEWS_LIKE

Only one primary regime may be active at a time.

A confidence value must also be produced.

Example

TRENDING_BULL

Confidence

87%

==================================================================

DATA SOURCES

The engine may use

OHLC

ATR

True Range

EMA slope

ADX (optional)

Standard deviation

Historical volatility

Swing analysis

Range expansion

Range contraction

Volume if available

No external DLLs.

No Python.

Pure MQL5.

==================================================================

FEATURES

The engine should compute:

ATR percentile

Rolling volatility

Average candle size

Impulse ratio

Correction ratio

EMA slope

Swing persistence

Range width

Breakout frequency

Expansion speed

Compression duration

Volatility clustering

Directional efficiency ratio

Fractal dimension approximation (optional)

Market noise ratio

==================================================================

REGIME CLASSIFICATION LOGIC

Trending

Higher highs

Higher lows

Positive efficiency ratio

Consistent directional movement

Bullish slope

Trending Bear

Mirror logic

Range

Low efficiency ratio

Multiple reversals

Small directional progress

Compression

ATR below historical percentile

Shrinking ranges

Expansion

Large consecutive candles

ATR rising rapidly

Breakout confirmed

Transition

Conflicting evidence

No clear direction

High Volatility

ATR percentile above threshold

Large intrabar movement

Low Volatility

ATR percentile below threshold

News-like

Exceptionally abnormal volatility

Large gaps

Very high ATR spike

==================================================================

OUTPUT STRUCTURE

Create a structure similar to

struct RegimeAnalysis
{
    ENUM_MARKET_REGIME regime;

    double confidence;

    double atrPercentile;

    double volatility;

    double trendStrength;

    double efficiencyRatio;

    double compressionScore;

    double expansionScore;

    datetime lastUpdate;
};

==================================================================

API

Design a clean interface.

Initialize()

Update()

Analyze()

GetCurrentRegime()

GetConfidence()

GetAnalysis()

Reset()

No global variables.

No hidden state.

==================================================================

CONFIGURATION

Every threshold must be user configurable.

Examples

ATR lookback

Volatility lookback

Compression threshold

Expansion threshold

Trend threshold

Minimum confidence

EMA period

Swing length

Maximum history

==================================================================

PERFORMANCE

Avoid repeated indicator creation.

Cache indicator handles.

Reuse buffers.

Avoid unnecessary loops.

Support backtests with millions of ticks.

Memory efficient.

==================================================================

LOGGING

Provide optional debug logging.

Example

[Regime]

ATR Percentile

82

Efficiency

0.73

Compression

12

Expansion

81

Result

TRENDING_BULL

Confidence

89%

==================================================================

VISUALIZATION

Optionally display

Current regime

Confidence

ATR percentile

Trend strength

Expansion score

Compression score

Volatility score

==================================================================

ERROR HANDLING

Gracefully handle

Insufficient history

Indicator failures

Invalid handles

Missing data

Broker inconsistencies

==================================================================

UNIT TESTING

Provide isolated test functions that verify

Trend detection

Range detection

Expansion detection

Compression detection

Transition detection

Confidence calculation

==================================================================

DELIVERABLES

Produce

Header files

Implementation files

Enumerations

Configuration

Documentation

Comments

Example usage

Integration instructions

No placeholder code.

No pseudocode.

Production-ready MQL5.

The implementation should be modular, extensible, memory efficient,
and suitable for institutional-grade algorithmic trading systems.


One architectural recommendation

I would make one change that will pay off enormously later.

Every engine should return the same interface pattern.

For example:
struct EngineResult
{
    bool        valid;
    double      confidence;
    datetime    timestamp;
};

struct RegimeResult : EngineResult
{
    ENUM_MARKET_REGIME regime;
    double trendStrength;
    double volatility;
    double efficiencyRatio;
};

struct LiquidityResult : EngineResult
{
    double score;
    ENUM_LIQUIDITY_TYPE type;
    bool swept;
};

struct StructureResult : EngineResult
{
    ENUM_STRUCTURE_STATE state;
    double strength;
};

struct ExecutionResult : EngineResult
{
    bool executable;
    double executionScore;
};