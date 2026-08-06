PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 04

Liquidity Engine

==================================================================

OBJECTIVE

Design and implement an institutional-grade Liquidity Engine in
pure MQL5.

This engine is responsible for discovering, classifying,
tracking, scoring and maintaining liquidity pools across multiple
timeframes.

The engine must NOT generate trade signals.

It must NOT execute trades.

It must only produce quantitative liquidity evidence for the
Trade Quality Index and Execution Engine.

The Liquidity Engine will become one of the highest weighted
evidence providers within Project Quantum.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

This module ONLY manages liquidity.

Do NOT

Execute trades

Calculate risk

Manage positions

Detect Order Blocks

Detect Fair Value Gaps

Detect Sessions

Calculate HTF Bias

Those belong to their own engines.

==================================================================

DESIGN PHILOSOPHY

Liquidity is NOT simply

Highest High

Lowest Low

Instead, model liquidity as a collection of statistically relevant
resting-order locations.

Each liquidity pool must possess measurable characteristics,
history, quality and confidence.

The engine should answer

Where is liquidity?

How important is it?

How likely is price to seek it?

Has it already been consumed?

Is new liquidity forming?

==================================================================

SUPPORTED LIQUIDITY TYPES

Equal Highs

Equal Lows

Swing High

Swing Low

Internal Liquidity

External Liquidity

Previous Session High

Previous Session Low

Previous Day High

Previous Day Low

Previous Week High

Previous Week Low

Previous Month High

Previous Month Low

Asian High

Asian Low

London High

London Low

New York High

New York Low

Trendline Liquidity

Range High

Range Low

Compression High

Compression Low

Untested Swing

Tested Swing

Double Top

Double Bottom

Triple Top

Triple Bottom

Round Number Liquidity

Psychological Levels

Volume Node Liquidity (optional)

VWAP Liquidity (optional)

==================================================================

LIQUIDITY OBJECT MODEL

Each liquidity level must be stored as an object.

Example

struct LiquidityLevel
{
    ENUM_LIQUIDITY_TYPE type;

    ENUM_TIMEFRAME timeframe;

    double price;

    datetime created;

    datetime lastTouched;

    bool active;

    bool swept;

    bool consumed;

    int touches;

    double score;

    double confidence;

    double distance;

    double strength;

    double freshness;

    double reactionScore;

    double probability;

};

==================================================================

LIQUIDITY CLASSIFICATION

Every detected level must be classified.

Examples

Weak

Medium

Strong

Major

Institutional

Score each level independently.

==================================================================

SCORING FACTORS

Calculate scores using evidence such as

Age

Freshness

Touch count

Untested status

Swing strength

Timeframe

Reaction size

Reaction speed

Reaction volume

ATR distance

Structure alignment

HTF Bias alignment

Session importance

Historical respect

Proximity to current price

Round number proximity

Range position

Cluster density

==================================================================

LIQUIDITY CLUSTERS

Nearby liquidity pools should be merged into clusters.

Calculate

Cluster size

Average score

Highest score

Density

Priority

Distance

Expected attraction

Clusters become higher-level evidence than single liquidity levels.

==================================================================

SWEEP DETECTION

Detect

Bullish Sweep

Bearish Sweep

Internal Sweep

External Sweep

Partial Sweep

Failed Sweep

Multiple Sweep

Liquidity Grab

False Break

Stop Hunt

Store

Sweep distance

Sweep velocity

Sweep candle

Recovery

Acceptance

Rejection

Sweep strength

==================================================================

POST-SWEEP ANALYSIS

After every sweep determine

Acceptance

Rejection

Immediate reversal

Continuation

Displacement

Retest

Confirmation

Reaction quality

==================================================================

LIQUIDITY MAP

Maintain a continuously updated liquidity map.

Track

Nearest liquidity

Highest score

Largest cluster

Untouched liquidity

Consumed liquidity

Emerging liquidity

Invalidated liquidity

==================================================================

LIQUIDITY PROBABILITY MODEL

Estimate probability that current price is attracted toward
each liquidity level.

Factors may include

Distance

ATR normalization

Historical attraction

Trend alignment

Current regime

Session

Volatility

Structure

Liquidity score

Recent sweeps

Cluster importance

Normalize

0–100%

==================================================================

MULTI-TIMEFRAME ANALYSIS

Support

MN

W1

D1

H4

H1

M30

M15

Merge overlapping liquidity intelligently.

Higher timeframe liquidity should generally carry greater weight,
but weighting must be configurable.

==================================================================

AGING MODEL

Liquidity importance changes with time.

Implement decay model.

Fresh liquidity

Higher score

Old consumed liquidity

Lower score

Untested liquidity

Higher score

Frequently tested liquidity

Lower score

==================================================================

OUTPUT STRUCTURES

Provide standardized outputs.

Example

struct LiquidityAnalysis
{
    LiquidityLevel nearest;

    LiquidityLevel strongest;

    LiquidityCluster highestCluster;

    double bullishLiquidityScore;

    double bearishLiquidityScore;

    double attractionProbability;

    double sweepProbability;

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

DetectLiquidity()

UpdateClusters()

DetectSweeps()

CalculateScores()

GetNearestLiquidity()

GetStrongestLiquidity()

GetLiquidityMap()

GetAnalysis()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

User configurable parameters

Swing length

Equal high tolerance

Equal low tolerance

Cluster distance

Maximum stored levels

Maximum history

Decay rate

Sweep threshold

ATR normalization

Minimum score

Minimum confidence

Higher timeframe weighting

Enable or disable liquidity types

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Incremental updates

No full rescans every tick

Cached swing history

Reusable buffers

Efficient memory management

Avoid duplicate liquidity objects

Support optimization runs efficiently.

==================================================================

LOGGING

Optional detailed logging.

Example

[Liquidity Engine]

Detected

Previous Day High

Price

1.28754

Score

91

Freshness

96

Touches

0

Cluster

Major External Liquidity

Attraction Probability

84%

Nearest Distance

18 pips

==================================================================

VISUALIZATION

Optional chart objects

Liquidity labels

Liquidity zones

Sweep arrows

Clusters

Consumed liquidity

Untested liquidity

Strength coloring

Distance labels

==================================================================

ERROR HANDLING

Gracefully handle

Insufficient bars

Missing history

Duplicate levels

Invalid prices

Broker precision differences

Symbol digit variations

Data synchronization issues

==================================================================

UNIT TESTING

Provide isolated tests for

Equal High detection

Equal Low detection

Swing detection

Cluster creation

Sweep detection

Probability calculation

Score calculation

Freshness decay

Multi-timeframe merging

Nearest liquidity search

==================================================================

INTEGRATION

Expose outputs to

Market Regime Engine

HTF Bias Engine

Institutional Zones Engine

Trade Quality Index

Execution Engine

Risk Engine

Dashboard

Self-Learning Statistics Engine

No module should independently detect liquidity.

All engines must consume standardized liquidity outputs.

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

Performance notes

Memory optimization notes

No placeholder code.

No pseudocode.

Institutional-quality production-ready MQL5.

The implementation must prioritize modularity,
computational efficiency, extensibility,
correctness and long-term maintainability.


There is one feature I would add that almost no retail EA has

This is what I call the Liquidity Graph.

Instead of storing liquidity as a flat list:
Level A

Level B

Level C

Level D

Represent it as a graph:
Previous Day High
        │
        │
Equal High Cluster
        │
        │
Weekly High
        │
        │
Monthly High

Each liquidity node knows:

Distance to neighboring liquidity.
Whether it belongs to a larger cluster.
Which higher-timeframe liquidity it reinforces.
Whether it has already been swept.
Whether price reacted after the sweep.

Now the engine doesn't just ask:

"Where is liquidity?"

It asks:

"What sequence of liquidity pools is price statistically most likely to interact with next?"

That transforms the Liquidity Engine from a detector into a probabilistic path-planning system.

For example, instead of simply reporting:

Previous Day High: score 82
Weekly High: score 91

it could infer:

Current Price
      │
      ▼
Equal High Cluster
      │
83% probability
      ▼
Previous Day High
      │
67% probability
      ▼
Weekly High
