PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 06

Session & Time Filters Engine
(Temporal Context Engine)

==================================================================

OBJECTIVE

Design and implement a fully modular Session & Time Filters Engine
in pure MQL5.

This engine is responsible for identifying institutional trading
sessions, market timing characteristics, session transitions,
time-based volatility patterns and temporal trading context.

The engine MUST NOT generate trading signals.

The engine MUST NOT execute trades.

Its sole responsibility is producing quantitative temporal evidence
for the Trade Quality Index and Execution Engine.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

This engine only analyzes temporal market context.

Do NOT

Execute trades

Manage positions

Calculate risk

Detect liquidity

Detect order blocks

Detect market structure

Detect FVGs

Those belong to their respective engines.

==================================================================

DESIGN PHILOSOPHY

Time is an institutional variable.

Institutional participation changes throughout the day.

Different sessions exhibit different behavior regarding

Liquidity

Volatility

Spread

Momentum

False breakouts

Trend continuation

Reversals

The engine should quantify these differences.

==================================================================

SUPPORTED SESSIONS

Sydney

Tokyo

Asian Session

London Pre-Open

London Open

London Session

London Kill Zone

London Close

New York Pre-Open

New York Open

New York Session

New York Kill Zone

New York Lunch

New York Close

London-New York Overlap

Friday Close

Weekend Gap

Holiday Session

Broker Roll Over

==================================================================

SESSION STATES

For every session determine

Not Started

Opening

Active

Peak Liquidity

Peak Volatility

Transition

Closing

Closed

==================================================================

TEMPORAL CONTEXT

Determine

Current session

Previous session

Next session

Time until session opens

Time until session closes

Time since open

Time since close

Session overlap

Institutional participation probability

==================================================================

SESSION PROFILE

For every session calculate

Average volatility

Average ATR

Average spread

Average candle size

Average volume (if available)

Average directional movement

Average liquidity sweeps

Average breakout frequency

Average reversal probability

Average continuation probability

==================================================================

SESSION QUALITY

Calculate

Liquidity Score

Volatility Score

Momentum Score

Execution Score

Institutional Participation Score

Reliability Score

Spread Quality

Noise Level

Trend Quality

Normalize all values

0–100

==================================================================

SESSION TRANSITIONS

Detect

Asian → London

London → New York

London Close

New York Close

Weekend Open

Broker Roll Over

Calculate

Transition volatility

Transition momentum

Gap probability

False breakout probability

==================================================================

TIME WINDOWS

Support configurable institutional windows

Opening Range

Kill Zones

Lunch

Low Liquidity Hours

High Liquidity Hours

Broker Roll Over

User-defined windows

==================================================================

SPECIAL EVENTS

Support temporal flags for

Friday afternoon

Monday open

Month end

Quarter end

Year end

Holiday trading

Broker maintenance

Low liquidity conditions

Optional economic calendar integration
(if unavailable, expose hooks for future integration)

==================================================================

TIME DECAY MODEL

Model the changing quality of a setup over time.

For example

A setup may lose quality after remaining
untriggered for several hours.

Support configurable temporal decay.

==================================================================

VOLATILITY TIMING MODEL

Measure

ATR changes by session

Expansion frequency

Compression frequency

Breakout probability

Mean reversion probability

Trend persistence

==================================================================

SPREAD ANALYSIS

Track

Current spread

Average spread by session

Spread percentile

Spread anomaly

Spread widening

Spread normalization

Generate

Spread Quality Score

==================================================================

MULTI-SYMBOL SUPPORT

Session calculations must work correctly for

Forex

Indices

Metals

Energy

Crypto (24/7 mode)

Session definitions must be configurable.

==================================================================

OUTPUT STRUCTURES

Provide standardized outputs.

Example

struct SessionAnalysis
{
    ENUM_SESSION currentSession;

    ENUM_SESSION_STATE state;

    double liquidityScore;

    double volatilityScore;

    double executionScore;

    double spreadScore;

    double participationScore;

    double confidence;

    bool overlap;

    bool killZone;

    bool lowLiquidity;

    datetime lastUpdate;
};

==================================================================

API

Provide

Initialize()

Update()

Analyze()

DetectCurrentSession()

CalculateSessionScores()

AnalyzeSpread()

AnalyzeVolatility()

GetCurrentSession()

GetSessionState()

GetAnalysis()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

User configurable

Session times

Time zone

DST adjustment

Kill Zone windows

Opening Range duration

Spread thresholds

Volatility thresholds

Participation thresholds

Temporal decay

Weekend behavior

Holiday handling

24/7 mode

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Incremental updates

Minimal time calculations

Cached session boundaries

Reusable buffers

No repeated datetime parsing

Memory efficient

==================================================================

LOGGING

Optional detailed logging.

Example

[Temporal Context Engine]

Current Session

London Kill Zone

State

Peak Liquidity

Liquidity Score

94

Volatility Score

87

Spread Score

91

Participation

96

Execution Quality

89

Confidence

92

==================================================================

VISUALIZATION

Optional chart display

Current session

Kill Zone markers

Session boundaries

Opening Range

Session labels

Volatility profile

Spread profile

Participation score

Countdown timers

==================================================================

ERROR HANDLING

Gracefully handle

Broker time offsets

DST transitions

Weekend gaps

Missing candles

Invalid server time

Holiday schedules

24/7 symbols

==================================================================

UNIT TESTING

Provide isolated tests for

Session detection

Kill Zone detection

Session overlap

DST adjustment

Spread analysis

Volatility analysis

Temporal decay

Participation scoring

Session transitions

==================================================================

INTEGRATION

Expose outputs to

Market Regime Engine

HTF Bias Engine

Liquidity Engine

Institutional Zones Engine

Trade Quality Index

Execution Engine

Risk Engine

Dashboard

Self-Learning Statistics Engine

No module should independently calculate
session context.

All modules must consume standardized
temporal outputs.

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

Institutional-quality production-ready MQL5.

The implementation must prioritize

Correctness

Scalability

Maintainability

Computational efficiency

Long-term extensibility.



One Feature I'd Add That Few Retail EAs Have

I would introduce a Session Personality Model.

Instead of treating every London Open or New York session the same, the engine learns the "character" of each session over time.

For each session, maintain rolling statistics such as:

Metric	London	New York	Asian
Avg ATR	21	24	11
Sweep Frequency	73%	81%	38%
Trend Continuation	69%	62%	29%
Mean Reversion	24%	31%	71%
Average Spread	0.8	1.0	1.6
Execution Quality	91	88	54

Rather than simply reporting:

"Current session: London"

the engine could conclude:

"The current London session historically exhibits high institutional participation, above-average volatility, tight spreads, and a strong tendency toward post-sweep trend continuation. Temporal context quality is high."