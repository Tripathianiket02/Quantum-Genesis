PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 10

Self-Learning Statistics Engine

(Pure MQL5)

==================================================================

OBJECTIVE

Design and implement a fully deterministic Self-Learning Statistics
Engine in pure MQL5.

This engine is responsible for collecting, storing, analyzing and
learning from historical trading performance.

The engine MUST NOT generate trading signals.

The engine MUST NOT execute trades.

The engine MUST NOT use external AI frameworks,
Python, TensorFlow, DLLs or cloud services.

Its sole responsibility is continuously improving the statistical
calibration of Project Quantum while remaining fully explainable,
reproducible and suitable for backtesting.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

Only analyze historical statistics.

Do NOT

Generate entries

Execute trades

Calculate liquidity

Detect structure

Calculate HTF bias

Manage positions

Modify broker settings

Learning only influences configurable weights and
probability calibration.

==================================================================

DESIGN PHILOSOPHY

Learning must be

Deterministic

Explainable

Incremental

Reversible

Statistically justified

The engine should never invent strategies.

It should answer

What conditions historically performed best?

Which evidence combinations produced
the highest expectancy?

Which market environments are consistently
profitable?

Which evidence should receive greater
or lower influence?

==================================================================

DATA COLLECTION

Record every completed trade.

Store

Ticket

Symbol

Timeframe

Direction

Entry Time

Exit Time

Entry Price

Exit Price

Stop Loss

Take Profit

Lot Size

Spread

Commission

Swap

Slippage

ATR

Volatility

Market Regime

HTF Bias

Liquidity Type

Liquidity Score

Institutional Zone Score

Order Block Quality

FVG Quality

Premium / Discount

Session

Trade Quality Index

Context Score

Setup Score

Execution Score

Consistency Score

Position Health History

Entry Model

Exit Reason

MFE

MAE

Maximum Drawdown

Maximum Favorable Excursion

R Multiple

Profit

Loss

Expectancy Contribution

==================================================================

STATISTICAL ANALYSIS

Calculate

Win Rate

Loss Rate

Profit Factor

Expectancy

Average Win

Average Loss

Average Holding Time

Average R

Maximum Drawdown

Recovery Factor

Sharpe Ratio (approximation)

Sortino Ratio (approximation)

Calmar Ratio (optional)

Equity Stability

Risk Efficiency

==================================================================

SEGMENT ANALYSIS

Analyze statistics by

Market Regime

HTF Bias

Session

Liquidity Type

Entry Model

Institutional Zone

Symbol

Timeframe

Volatility

Spread

Day of Week

Hour of Day

Trade Direction

==================================================================

PATTERN DISCOVERY

Discover statistically significant relationships.

Examples

London Kill Zone

Liquidity Sweep Reversal

Win Rate

81%

Average R

2.4

Sample

412 Trades

------------------------------------------------------------

Bearish Trend

Asian Session

Mean Reversion

Win Rate

39%

Average R

0.6

Sample

281 Trades

==================================================================

WEIGHT CALIBRATION

Support adaptive adjustment of

Engine weights

Evidence confidence

Conflict penalties

Probability calibration

Thresholds

Learning adjustments must remain inside
user-defined safety bounds.

Example

Liquidity Weight

Original

18%

Adjusted

20%

Maximum Allowed

22%

==================================================================

CONFIDENCE CALIBRATION

Compare

Predicted Probability

Actual Outcome

Measure calibration error.

Adjust confidence scaling gradually.

Never overreact to small samples.

==================================================================

SAMPLE VALIDATION

Require minimum sample sizes.

Examples

Minimum Trades

100

Minimum Winning Trades

30

Minimum Losing Trades

30

Minimum Confidence

95%

Reject statistically weak conclusions.

==================================================================

ROLLING LEARNING

Support

Rolling Window

Recent Trades

Lifetime Trades

Hybrid Model

User configurable.

==================================================================

DECAY MODEL

Recent trades should gradually receive
greater influence.

Support configurable decay.

Linear

Exponential

Piecewise

==================================================================

OUTLIER DETECTION

Identify

Abnormal wins

Abnormal losses

Execution anomalies

Spread spikes

News events

Broker anomalies

Exclude optional outliers from learning.

==================================================================

MODEL STABILITY

Prevent overfitting.

Support

Learning rate

Maximum adjustment

Minimum adjustment interval

Confidence threshold

Rollback capability

Learning freeze

==================================================================

OUTPUT STRUCTURES

Provide standardized outputs.

Example

struct LearningAnalysis
{
    double profitFactor;

    double expectancy;

    double calibrationError;

    double modelStability;

    double confidence;

    int totalTrades;

    int qualifiedTrades;

    bool learningActive;

    datetime lastLearningUpdate;
};

==================================================================

API

Provide

Initialize()

RecordTrade()

UpdateStatistics()

AnalyzeHistory()

DiscoverPatterns()

CalibrateWeights()

ValidateSamples()

GenerateLearningReport()

GetLearningAnalysis()

Reset()

No global variables.

No hidden dependencies.

==================================================================

CONFIGURATION

User configurable

Minimum sample

Learning rate

Maximum weight adjustment

Decay model

Rolling window

Confidence threshold

Outlier handling

Learning frequency

Rollback limits

Enable / Disable adaptive learning

==================================================================

PERFORMANCE

Designed for

Millions of historical trades

Incremental updates

Efficient storage

Reusable buffers

Memory efficient

Minimal CPU usage

==================================================================

LOGGING

Optional detailed logging.

Example

[Learning Engine]

Qualified Trades

1248

Profit Factor

2.31

Expectancy

0.84R

Liquidity Sweeps

Best Model

Weight Adjustment

+1.2%

Calibration Error

4.1%

Model Stability

97

==================================================================

VISUALIZATION

Display

Profit Factor

Expectancy

Win Rate

Calibration Error

Learning Status

Weight Changes

Best Performing Models

Historical Stability

==================================================================

ERROR HANDLING

Gracefully handle

Corrupted data

Insufficient samples

Incomplete history

Duplicate trades

Storage failures

Rollback failures

==================================================================

UNIT TESTING

Provide isolated tests for

Trade recording

Statistical calculations

Pattern discovery

Weight calibration

Confidence calibration

Decay model

Sample validation

Rollback logic

==================================================================

INTEGRATION

Consume outputs from

Trade Quality Index

Execution Engine

Risk Engine

Dashboard

Analytics

Expose calibrated parameters to

Trade Quality Index

Risk Engine

Execution Engine

Never modify analytical engine logic directly.

Only adjust configurable evidence weights
within approved safety limits.

==================================================================

DELIVERABLES

Produce

Production-ready .mqh interfaces

Implementation files

Trade database structures

Configuration

Documentation

Usage examples

Integration guide

Performance notes

Memory optimization notes

No placeholder code.

No pseudocode.

Production-ready institutional-quality MQL5.

The implementation must prioritize

Statistical correctness

Explainability

Determinism

Maintainability

Scalability

Long-term robustness.

==================================================


The Biggest Improvement I'd Add: Evidence Attribution Matrix

This is the feature I think can elevate Project Quantum from a good adaptive EA into a genuine quantitative research platform.

Instead of only recording the outcome of a trade, record which evidence actually contributed to that outcome.

For every completed trade, build an attribution matrix like this:
| Evidence Engine     | Weight at Entry | Outcome Contribution |
| ------------------- | --------------: | -------------------: |
| Market Regime       |            0.91 |             Positive |
| HTF Bias            |            0.88 |             Positive |
| Liquidity           |            0.95 |      Strong Positive |
| Institutional Zones |            0.82 |             Positive |
| Session Context     |            0.76 |              Neutral |
| Execution Quality   |            0.93 |             Positive |
| Risk Management     |            0.97 |             Positive |

Now imagine the engine processes 10,000 trades.

Instead of concluding:

"Liquidity Sweeps work well."

It can conclude something far more precise:

Liquidity evidence is highly predictive only when HTF Bias is above 80 and Session Quality exceeds 75.
Premium/Discount adds little value during ranging regimes but significantly improves expectancy in trending markets.
The Trade Quality Index tends to be overconfident during low-liquidity sessions and should be recalibrated downward.
Certain entry models produce strong results only when the Position Health remains above a defined threshold during the first phase of the trade.