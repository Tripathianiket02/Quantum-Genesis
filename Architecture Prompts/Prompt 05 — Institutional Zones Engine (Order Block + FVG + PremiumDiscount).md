PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 05

Institutional Zones Engine

(Order Blocks + Fair Value Gaps + Premium / Discount)

==================================================================

OBJECTIVE

Design and implement an institutional-grade pricing and imbalance
analysis engine in pure MQL5.

The engine must identify, classify, score and maintain institutional
pricing zones including Order Blocks, Fair Value Gaps, Breakers,
Mitigation Blocks, Balanced Price Ranges and Premium / Discount
areas.

The engine MUST NOT execute trades.

The engine MUST NOT calculate risk.

Its only responsibility is producing high-quality institutional
pricing evidence for the Trade Quality Index and Execution Engine.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

Only analyze institutional pricing zones.

Do NOT

Execute trades

Manage positions

Calculate HTF Bias

Calculate Liquidity

Calculate Sessions

Manage Risk

Generate entry signals

Those belong to their respective engines.

==================================================================

DESIGN PHILOSOPHY

Institutional zones are not binary.

An Order Block is never simply

Valid

Invalid

Every zone possesses measurable quality.

The engine should answer

Where are institutional pricing zones?

How strong are they?

Have they already been mitigated?

Are they still respected?

Are they aligned with higher timeframe context?

Are they supported by imbalance?

How attractive is current price relative to institutional value?

==================================================================

SUPPORTED ZONE TYPES

Bullish Order Block

Bearish Order Block

Internal Order Block

External Order Block

Breaker Block

Mitigation Block

Rejection Block

Supply Zone

Demand Zone

Fair Value Gap (FVG)

Inverse Fair Value Gap (IFVG)

Balanced Price Range (BPR)

Volume Imbalance

Opening Gap

Exhaustion Gap

Continuation Gap

Institutional Repricing Zone

Premium Zone

Discount Zone

Equilibrium

==================================================================

ORDER BLOCK DETECTION

Support configurable institutional definitions.

Detect

Bullish Order Blocks

Bearish Order Blocks

Strong Order Blocks

Weak Order Blocks

Fresh Order Blocks

Mitigated Order Blocks

Consumed Order Blocks

Failed Order Blocks

Nested Order Blocks

Multi-timeframe Order Blocks

Store

Creation candle

Price boundaries

Volume characteristics (if available)

Associated BOS

Associated CHOCH

Reaction quality

Freshness

Touches

Mitigation count

Strength

Confidence

==================================================================

ORDER BLOCK QUALITY MODEL

Calculate a quality score using

Impulse strength

Displacement

Reaction distance

Reaction speed

Volume confirmation

Freshness

Mitigation status

Touch count

Alignment with HTF Bias

Alignment with Liquidity

Alignment with Market Regime

Session context

ATR normalization

Historical respect

Normalize

0–100

==================================================================

FAIR VALUE GAP DETECTION

Detect

Bullish FVG

Bearish FVG

Partial Fill

Full Fill

Nested FVG

Stacked FVG

Overlapping FVG

Multi-timeframe FVG

Store

Start

End

Width

Age

Fill percentage

Fill speed

Associated displacement

Associated Order Block

Associated BOS

Associated liquidity

==================================================================

FVG QUALITY MODEL

Calculate

Gap size

ATR normalized width

Fill probability

Fill percentage

Reaction quality

Time survived

Alignment with trend

Alignment with HTF Bias

Alignment with liquidity

Session importance

Freshness

Normalize

0–100

==================================================================

BALANCED PRICE RANGE

Detect BPR automatically.

Measure

Width

Duration

Balance quality

Breakout probability

Alignment with structure

Institutional importance

==================================================================

VOLUME IMBALANCE

Detect directional imbalance using candle structure.

Calculate

Strength

Persistence

Continuation probability

Exhaustion probability

==================================================================

PREMIUM / DISCOUNT ENGINE

Implement institutional dealing range analysis.

Support

Premium

Discount

Equilibrium

Configurable dealing range sources

Swing-based

HTF structure

User defined

Adaptive

Calculate

Current position within range

Distance to equilibrium

Premium percentage

Discount percentage

Mean reversion probability

==================================================================

INSTITUTIONAL PRICING SCORE

Generate pricing evidence from

Order Block quality

FVG quality

Premium / Discount

Mitigation status

Displacement

Imbalance

Historical respect

HTF alignment

Liquidity alignment

Market regime alignment

Session alignment

Normalize

0–100

==================================================================

ZONE LIFE CYCLE

Track

New

Active

Retested

Partially Mitigated

Fully Mitigated

Consumed

Invalidated

Archived

Maintain complete lifecycle history.

==================================================================

MULTI-TIMEFRAME ANALYSIS

Support

Monthly

Weekly

Daily

H4

H1

M30

M15

Merge overlapping institutional zones.

Allow higher timeframe zones to dominate lower timeframe zones.

Weighting must be configurable.

==================================================================

OUTPUT STRUCTURES

Create standardized structures.

Example

struct InstitutionalZone
{
    ENUM_ZONE_TYPE type;

    ENUM_TIMEFRAME timeframe;

    double upper;

    double lower;

    datetime created;

    bool active;

    bool mitigated;

    bool consumed;

    double quality;

    double confidence;

    double reactionScore;

    double probability;
};

struct InstitutionalAnalysis
{
    InstitutionalZone nearest;

    InstitutionalZone strongest;

    double orderBlockScore;

    double fvgScore;

    double premiumDiscountScore;

    double imbalanceScore;

    double institutionalPricingScore;

    double confidence;

    bool valid;

    datetime lastUpdate;
};

==================================================================

API

Provide

Initialize()

Update()

Analyze()

DetectOrderBlocks()

DetectFVG()

DetectBPR()

DetectImbalance()

CalculatePremiumDiscount()

CalculateScores()

GetNearestZone()

GetStrongestZone()

GetInstitutionalAnalysis()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

Every threshold must be configurable.

Swing length

Minimum impulse

Minimum displacement

Minimum FVG width

Maximum FVG age

Premium threshold

Discount threshold

Equilibrium tolerance

Mitigation tolerance

Maximum stored zones

History depth

Multi-timeframe weights

Enable / Disable zone types

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Incremental updates

Cached swing structures

Efficient memory allocation

Reusable buffers

No duplicate zone detection

Avoid recalculating historical zones unless necessary

==================================================================

LOGGING

Optional detailed logging.

Example

[Institutional Zones]

Bullish Order Block

H4

Quality

91

Freshness

95

Mitigation

0

Confidence

88

Bullish FVG

Width

17 pips

Fill

21%

Quality

84

Current Price

Discount

18%

Institutional Pricing Score

89

==================================================================

VISUALIZATION

Optional chart objects

Order Block rectangles

FVG rectangles

Premium / Discount shading

Equilibrium line

BPR zones

Mitigation markers

Zone labels

Quality scores

==================================================================

ERROR HANDLING

Gracefully handle

Insufficient history

Overlapping zones

Duplicate zones

Invalid prices

Broker precision differences

Missing candles

Data synchronization issues

==================================================================

UNIT TESTING

Provide isolated tests for

Bullish Order Block detection

Bearish Order Block detection

Mitigation detection

FVG detection

Partial fills

Full fills

BPR detection

Premium calculation

Discount calculation

Zone quality scoring

Institutional pricing score

==================================================================

INTEGRATION

Expose outputs to

Market Regime Engine

HTF Bias Engine

Liquidity Engine

Trade Quality Index

Execution Engine

Risk Engine

Dashboard

Self-Learning Statistics Engine

No module should independently detect institutional zones.

All engines must consume standardized outputs from this module.

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

Performance optimization notes

Memory optimization notes

No placeholder code.

No pseudocode.

Production-ready institutional-quality MQL5 suitable for a
modular quantitative execution platform.

The implementation must prioritize correctness,
computational efficiency,
extensibility,
maintainability,
and long-term scalability.

One Feature I'd Add Beyond Traditional SMC

This is something I would specifically add for Project Quantum because it fits the probabilistic architecture you've been building:

Institutional Zone Interaction Matrix

Don't evaluate Order Blocks, FVGs, and Premium/Discount independently.

Instead, build an interaction matrix.

For example:

Evidence	Weight	Status
H4 Bullish Order Block	92	Active
H1 Bullish FVG	84	Unfilled
Current Price in Discount	88	Yes
Nearby External Liquidity	79	Above Price
HTF Bias	90	Bullish
Market Regime	86	Trending Bull

Instead of saying:

"There is a Bullish Order Block."

the engine concludes something richer:

"Current price sits inside a high-quality H4 institutional demand zone, reinforced by an unfilled H1 Fair Value Gap, positioned in discount within a bullish dealing range, aligned with higher-timeframe structure and a trending bullish regime."

That becomes institutional pricing evidence, not a trading signal.