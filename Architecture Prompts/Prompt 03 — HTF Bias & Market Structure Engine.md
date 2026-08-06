PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 03

HTF Bias & Market Structure Engine

==================================================================

OBJECTIVE

Design and implement a fully modular High Timeframe (HTF) Bias &
Market Structure Engine in pure MQL5.

This engine is responsible for determining institutional directional
bias and objectively describing market structure across multiple
timeframes.

The engine must NOT generate trading signals.

It must NOT execute trades.

Its only responsibility is to analyze market structure and produce
high-quality evidence for the Trade Quality Index.

This module will become the primary directional filter used by every
other engine.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle

The engine only analyzes market structure.

Do NOT

Execute trades

Manage positions

Calculate risk

Detect order blocks

Detect FVGs

Detect liquidity

Calculate session filters

Those responsibilities belong to other engines.

==================================================================

DESIGN GOALS

The engine must answer

What is the dominant institutional trend?

Which timeframe controls the market?

Is structure healthy?

Has structure shifted?

Where is price within the current structure?

Is current movement impulsive or corrective?

How aligned are multiple timeframes?

==================================================================

SUPPORTED TIMEFRAMES

Weekly

Daily

H4

H1

M30

M15

The engine must support enabling or disabling individual
timeframes through configuration.

==================================================================

MARKET STRUCTURE MODEL

For every timeframe detect

Swing High

Swing Low

Higher High (HH)

Higher Low (HL)

Lower High (LH)

Lower Low (LL)

Break of Structure (BOS)

Change of Character (CHOCH)

Market Structure Shift (MSS)

Internal Structure

External Structure

Impulse Leg

Correction Leg

Trend Continuation

Trend Exhaustion

Failed BOS

Liquidity-Induced BOS (flag only, no liquidity logic)

Nested Structures

Structure Compression

Structure Expansion

==================================================================

INSTITUTIONAL BIAS

Each timeframe must independently classify bias.

Possible outputs

STRONGLY_BULLISH

BULLISH

WEAK_BULLISH

NEUTRAL

WEAK_BEARISH

BEARISH

STRONGLY_BEARISH

UNKNOWN

Bias should be determined using evidence including

HH/HL progression

LH/LL progression

Recent BOS

CHOCH

Swing persistence

Impulse quality

Correction depth

Directional efficiency

Structure consistency

The engine must NOT rely on EMA crossover as the primary bias.

Moving averages may be used only as secondary evidence.

==================================================================

MULTI-TIMEFRAME ALIGNMENT

Calculate directional agreement across all enabled
timeframes.

Example

Weekly

Bullish

Daily

Bullish

H4

Bullish

H1

Bullish

Alignment

96%

Another example

Weekly

Bullish

Daily

Bullish

H4

Bearish

H1

Bearish

Alignment

58%

This alignment score becomes an important input for the
Trade Quality Index.

==================================================================

STRUCTURE QUALITY

Calculate quality scores

Trend Strength

Swing Quality

Structure Consistency

Impulse Quality

Correction Health

Continuation Probability

Reversal Probability

Noise Level

Trend Maturity

Structure Stability

Each score should be normalized between

0–100

==================================================================

SWING DETECTION

Swing identification must be configurable.

Support

Fractal-based swings

Lookback swings

Adaptive swing length based on ATR (optional)

Store swing history efficiently.

Each swing should contain

Price

Time

Type

Strength

Timeframe

Relative importance

==================================================================

BOS DETECTION

Detect

Bullish BOS

Bearish BOS

Internal BOS

External BOS

Weak BOS

Strong BOS

False BOS

Store

Break level

Break candle

Break strength

Break distance

Break momentum

Break confirmation

==================================================================

CHOCH DETECTION

Detect valid Change of Character events.

Evaluate

Strength

Distance

Momentum

Confirmation

Store complete CHOCH history.

==================================================================

IMPULSE ANALYSIS

For each impulse calculate

Distance

Duration

Average candle size

ATR multiple

Velocity

Momentum score

Volume score (if available)

Efficiency ratio

==================================================================

CORRECTION ANALYSIS

For every pullback calculate

Depth

Duration

Speed

Retracement percentage

Fibonacci position (optional)

Correction quality

Trend preservation probability

==================================================================

OUTPUT STRUCTURES

Create standardized structures.

Example

struct TimeframeBias
{
    ENUM_TIMEFRAME tf;

    ENUM_BIAS bias;

    double confidence;

    double trendStrength;

    double alignment;

    bool valid;
};

struct StructureAnalysis
{
    ENUM_STRUCTURE_STATE state;

    ENUM_BIAS bias;

    double confidence;

    double trendStrength;

    double swingQuality;

    double impulseQuality;

    double correctionQuality;

    double continuationProbability;

    double reversalProbability;

    double stability;

    datetime lastUpdate;
};

==================================================================

API

Provide clean interfaces.

Initialize()

Update()

Analyze()

AnalyzeTimeframe()

GetBias()

GetStructure()

GetAlignment()

GetTrendStrength()

GetCurrentState()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

Every threshold must be configurable.

Swing lookback

Fractal length

Minimum BOS size

Minimum impulse size

Minimum correction depth

Trend confidence threshold

Alignment weights

Enabled timeframes

History depth

Maximum stored swings

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Minimal memory allocation

Cached price access

Reusable buffers

No repeated indicator creation

Incremental updates

Avoid recalculating historical structures unless required.

==================================================================

LOGGING

Optional detailed logging.

Example

[Structure Engine]

Weekly

Bullish

Confidence

91

Daily

Bullish

Confidence

88

H4

Bullish

Confidence

84

H1

Weak Bullish

Confidence

69

Alignment

87%

Trend Strength

82

Continuation Probability

78

Structure

Healthy Bullish

==================================================================

VISUALIZATION

Optional chart objects.

Display

Current bias

Current BOS

CHOCH labels

Swing points

Structure lines

Trend strength

Alignment score

Current dominant timeframe

Structure state

==================================================================

ERROR HANDLING

Handle gracefully

Insufficient bars

Missing history

Invalid indicator handles

Data synchronization issues

Broker inconsistencies

Partial timeframe availability

==================================================================

UNIT TESTING

Provide isolated tests for

Swing detection

HH/HL recognition

LH/LL recognition

Bullish BOS

Bearish BOS

CHOCH detection

Impulse analysis

Correction analysis

Alignment calculation

Bias calculation

==================================================================

INTEGRATION

Expose outputs for

Market Regime Engine

Liquidity Engine

Institutional Zones Engine

Trade Quality Index

Execution Engine

Risk Engine

Dashboard

Self-Learning Engine

No engine should independently recalculate HTF bias.

All modules must consume this engine's standardized outputs.

==================================================================

DELIVERABLES

Produce

Production-ready .mqh interfaces

Implementation files

Enumerations

Configuration

Documentation

Usage examples

Integration guide

Performance considerations

No placeholder code.

No pseudocode.

Production-quality MQL5 suitable for an institutional-grade
quantitative execution platform.

The implementation must prioritize correctness, modularity,
maintainability, scalability, and computational efficiency.


One Enhancement Beyond the Original Design

I'd actually make this engine even more powerful by introducing a Structure Tree.

Instead of viewing each timeframe independently, represent them hierarchically:
Weekly
│
├── Daily
│   ├── H4
│   │   ├── H1
│   │   │   ├── M30
│   │   │   │   └── M15

Each child inherits context from its parent but can temporarily diverge. This lets the engine recognize scenarios like:

Weekly: Strong Bullish
Daily: Bullish Pullback
H4: Bearish Correction
H1: Bullish Reversal
M15: Bullish BOS

Rather than treating that as "conflicting signals," the engine can identify it as a lower-timeframe reversal occurring within a higher-timeframe bullish correction. That distinction is extremely valuable because many high-probability institutional entries occur precisely when lower timeframes reverse back into the dominant higher-timeframe trend.