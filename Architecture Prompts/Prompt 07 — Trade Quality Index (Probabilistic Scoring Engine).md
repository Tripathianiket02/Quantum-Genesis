Trade Quality Index Architecture

                Market Evidence
                      │
──────────────────────┼──────────────────────

Context Layer

Regime

HTF Bias

Session

Volatility

↓

Context Score

↓

Setup Layer

Liquidity

Institutional Zones

Premium/Discount

Structure Alignment

↓

Setup Score

↓

Execution Layer

Spread

ATR

Distance

RR

Execution Conditions

↓

Execution Score

↓

Consistency Layer

Do all evidence engines agree?

↓

Conflict Penalty

↓

Probability Calibration

↓

Trade Quality Index

0-100
==================================================================

PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 07

Trade Quality Index
(Probabilistic Scoring Engine)

==================================================================

OBJECTIVE

Design and implement the central probabilistic decision engine
for Project Quantum.

This module is responsible for aggregating evidence produced by
all analytical engines and transforming it into a normalized,
interpretable and statistically meaningful Trade Quality Index (TQI).

This module MUST NOT execute trades.

This module MUST NOT calculate entries.

Its responsibility is only to estimate the quality of the current
trading opportunity.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

The TQI engine only evaluates evidence.

It must NOT

Detect liquidity

Detect market structure

Detect order blocks

Detect sessions

Calculate HTF bias

Manage positions

Execute trades

Every input must originate from standardized outputs of the
specialized engines.

==================================================================

DESIGN PHILOSOPHY

Do NOT build a simple weighted sum.

Instead construct a hierarchical evidence model.

The engine must answer

How strong is the current context?

How strong is the current setup?

How executable is the opportunity?

How consistent are all evidence engines?

What is the probability that this setup belongs
to our high-quality statistical distribution?

==================================================================

ENGINE INPUTS

Market Regime Engine

HTF Bias Engine

Liquidity Engine

Institutional Zones Engine

Temporal Context Engine

Future

Execution Engine

Risk Engine

Learning Engine

Every engine provides standardized confidence values.

==================================================================

SCORING HIERARCHY

Layer 1

Context

Market Regime

HTF Bias

Volatility

Session

Trend Strength

Structure Stability

↓

Context Score

0–100

---------------------------------------------------------------

Layer 2

Setup

Liquidity

Institutional Zones

Order Block

FVG

Premium

Discount

Displacement

Imbalance

↓

Setup Score

0–100

---------------------------------------------------------------

Layer 3

Execution Readiness

Spread

ATR

Distance

Risk

Reward

Execution Environment

↓

Execution Score

0–100

---------------------------------------------------------------

Layer 4

Evidence Consistency

Agreement between engines

Conflict detection

Missing evidence

Contradictory evidence

↓

Consistency Score

0–100

==================================================================

FINAL TRADE QUALITY INDEX

The engine should produce

Context Score

Setup Score

Execution Score

Consistency Score

Final Trade Quality Index

Confidence

Expected Direction

Trade Classification

==================================================================

TRADE CLASSIFICATION

Example

AVOID

POOR

LOW QUALITY

MODERATE

GOOD

HIGH QUALITY

INSTITUTIONAL GRADE

EXCEPTIONAL

Thresholds configurable.

==================================================================

CONFLICT ANALYSIS

Detect situations such as

Bullish HTF Bias

Bearish Liquidity

Bullish Order Block

Bearish Session

Weak Regime

The engine should calculate

Conflict Severity

Evidence Agreement

Confidence Reduction

Penalty Score

==================================================================

EVIDENCE WEIGHTING

Every evidence source must support

Static weights

Adaptive weights

Learning-based weights

Future optimization

Weights must be configurable.

==================================================================

PROBABILITY CALIBRATION

Transform raw evidence into

Estimated Success Probability

Estimated Failure Probability

Confidence Interval

Expected Reliability

Calibration should be monotonic.

Avoid overconfident outputs.

==================================================================

EXPECTANCY ESTIMATION

Estimate

Expected Reward

Expected Risk

Expected R-Multiple

Estimated Profit Factor Contribution

Expected Trade Quality

Expected Statistical Edge

==================================================================

NORMALIZATION

Normalize every intermediate score

0–100

Use configurable normalization functions.

Support

Linear

Logarithmic

Sigmoid

Piecewise

==================================================================

OUTPUT STRUCTURES

Provide standardized outputs.

Example

struct TradeQualityAnalysis
{
    double contextScore;

    double setupScore;

    double executionScore;

    double consistencyScore;

    double tradeQualityIndex;

    double confidence;

    double successProbability;

    double expectancy;

    ENUM_DIRECTION direction;

    ENUM_TRADE_CLASS quality;

    bool executable;

    datetime lastUpdate;
};

==================================================================

API

Provide

Initialize()

Update()

Evaluate()

CalculateContext()

CalculateSetup()

CalculateExecution()

CalculateConsistency()

CalculateProbability()

GetTradeQuality()

GetAnalysis()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

User configurable

Engine weights

Normalization

Thresholds

Conflict penalties

Confidence scaling

Trade quality thresholds

Minimum executable score

Probability calibration

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Incremental calculations

Minimal allocations

Cached evidence

Reusable structures

Memory efficient

==================================================================

LOGGING

Optional detailed logging.

Example

[TQI]

Context

91

Setup

88

Execution

83

Consistency

94

Trade Quality Index

90

Estimated Success

78%

Confidence

92%

Classification

Institutional Grade

==================================================================

VISUALIZATION

Display

Context Score

Setup Score

Execution Score

Consistency

Final TQI

Confidence

Classification

Expected Direction

==================================================================

ERROR HANDLING

Gracefully handle

Missing engine outputs

Invalid confidence

Partial data

Conflicting evidence

Disabled modules

==================================================================

UNIT TESTING

Provide isolated tests for

Context scoring

Setup scoring

Execution scoring

Conflict analysis

Normalization

Probability calibration

Classification

Expectancy estimation

==================================================================

INTEGRATION

Consume

Market Regime Engine

HTF Bias Engine

Liquidity Engine

Institutional Zones Engine

Temporal Context Engine

Expose outputs to

Execution Engine

Risk Engine

Dashboard

Learning Engine

Analytics

No engine should duplicate TQI logic.

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

No placeholder code.

No pseudocode.

Institutional-quality production-ready MQL5 suitable for a
modular quantitative execution platform.

The implementation must prioritize

Correctness

Interpretability

Computational efficiency

Extensibility

Maintainability

Long-term scalability.

=============================================================

The Biggest Improvement I'd Add: Bayesian Evidence Fusion

This is the one enhancement that I think could set Project Quantum apart from almost every retail EA.

Instead of treating evidence as independent scores, update the probability as each engine contributes evidence:
Prior Probability
        │
        ▼
Market Regime Evidence
        │
        ▼
Updated Probability
        │
        ▼
HTF Bias Evidence
        │
        ▼
Updated Probability
        │
        ▼
Liquidity Evidence
        │
        ▼
Updated Probability
        │
        ▼
Institutional Zones Evidence
        │
        ▼
Updated Probability
        │
        ▼
Session Evidence
        │
        ▼
Final Posterior Probability