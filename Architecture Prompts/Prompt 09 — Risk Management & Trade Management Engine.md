PROJECT QUANTUM
Institutional Quantitative Execution Engine

MODULE 09

Risk Engine & Position Lifecycle Engine

==================================================================

NOTE ON THIS MODULE'S SCOPE (ADR-001 Reconciliation, 2026-08-12)

SYSTEM_ARCHITECTURE.md Section 8 defines Risk Engine and Position
Lifecycle Engine as two separate engines, with different
responsibilities and different lifecycle phases. This module
document specifies both, kept in one file for authoring
convenience, but they are two separate engines and must not be
implemented as one combined module.

  PART A — RISK ENGINE
    Pre-trade only. Runs after Trade Quality, before Execution.
    Produces one RiskState per TradeDecision, then its involvement
    with that trade ends.

  PART B — POSITION LIFECYCLE ENGINE
    Post-fill only. Runs after Execution confirms a broker fill.
    Owns the trade from that point until final close, including
    reconstructing it after a restart.

An earlier draft of this module also specified portfolio-wide and
cross-symbol functionality: portfolio risk allocation, correlation
management between symbols/currencies, sector and currency
exposure, and account-wide daily/weekly/monthly risk budgets.
Per ADR-001 (Symbol-Scoped Runtime Architecture), no core Quantum
engine has visibility into another instance's runtime state, so
none of that is computable inside a single symbol-scoped instance.
That content has been removed from the active scope below and is
listed under DEFERRED / OUT OF SCOPE near the end of this document,
together with the ADR that would be required to bring any of it
back in.

Wherever this document previously said "portfolio," "account,"
or "correlation," it now says "instance" where the underlying
capability is legitimately computable from this instance's own
history (e.g. this instance's own daily loss, this instance's own
drawdown) — those are kept. Where the capability genuinely requires
seeing another symbol or another instance's state, it has been
removed, not renamed.

==================================================================
PART A — RISK ENGINE
==================================================================

OBJECTIVE

Design and implement an institutional-grade Risk Engine in pure
MQL5.

This engine is responsible for protecting capital and sizing
positions before a trade is placed. It receives a qualified
TradeDecision from the Trade Quality Engine and produces one
RiskState: either an approval (with size, stop, and target) or a
rejection (with a specific reason).

It MUST NOT determine market direction or trading setups — that is
upstream, in the Trade Quality Engine and the engines that feed it.

It MUST NOT manage a position after it is filled — that is
Part B, the Position Lifecycle Engine. The Risk Engine's
involvement with a given trade ends the moment it produces a
RiskState.

Its sole responsibility is: given one proposed trade on this
instance's symbol, is it allowed, and if so, how large?

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

Only evaluate and size proposed trades, pre-fill.

Do NOT

Detect liquidity

Calculate HTF bias

Detect order blocks

Calculate TQI

Generate entries

Detect sessions

Manage an already-open position (Part B's job)

Coordinate with, or assume visibility into, another symbol or
another Quantum instance (ADR-001, Sections 12–15)

Those belong to upstream engines, to Part B, or are out of scope
entirely — see DEFERRED / OUT OF SCOPE.

==================================================================

DESIGN PHILOSOPHY

The Risk Engine's lifecycle is short and ends before the order
exists:

Pre-Trade Validation

↓

Position Sizing

↓

Stop Loss / Take Profit Derivation

↓

RiskState Output (Approved or Rejected)

It does not continue into monitoring or management. Once a
RiskState is produced and the order is sent, ownership of that
trade passes to Execution and then to Part B.

==================================================================

POSITION SIZING

Support multiple sizing models

Fixed Lot

Fixed Dollar Risk

Fixed Percentage Risk

ATR Risk

Volatility Adjusted Risk

Kelly Criterion (optional)

Fractional Kelly

Confidence Weighted Risk

Maximum Exposure Model

Position sizing must support configurable caps.

Note: any model that reads account equity or balance (Fixed
Percentage Risk, Volatility Adjusted Risk) is reading a value
shared across every Quantum instance on this account — see
ADR-001, Section 14.1. This engine still computes its own size
correctly from that shared value; it just does not pretend the
result is financially independent of other running instances.

==================================================================

PRE-TRADE VALIDATION

Verify

Maximum instance daily loss (this instance's own closed trades
today, filtered by this instance's Symbol + Magic)

Maximum instance weekly loss

Maximum open trades (this instance)

Maximum symbol exposure

Margin availability

Broker requirements

Trading session restrictions

Instance drawdown limit (this instance's own equity curve, not
account-wide — see Part B, INSTANCE DRAWDOWN CONTROL, for the
open-position-driven variant of this same limit)

Instance risk budget availability

Reject execution if any limit is exceeded, with a specific,
loggable reason (feeds RejectionReason in RiskState).

==================================================================

STOP LOSS ENGINE

Support

Structure-based Stop Loss

Liquidity-based Stop Loss

ATR Stop Loss

Volatility Stop

Order Block Stop

Swing Stop

Time-based Stop

Emergency Stop

Dynamic Stop

Broker minimum stop level validation

==================================================================

TAKE PROFIT ENGINE

Support

Fixed R-Multiple

Liquidity Target

HTF Structure Target

Multi-Level Targets

ATR Projection

Adaptive Targets

Partial Take Profit (initial target only — ongoing partial-close
execution during the trade's life is Part B's job)

Time-based Exit (initial target only — see Part B for exit
optimization during the trade's life)

==================================================================

INSTANCE RISK LIMITS

Support, scoped to this instance only — never account-wide or
cross-symbol (ADR-001, Sections 13–15):

Maximum instance risk (this instance's total open + pending risk)

Maximum symbol risk (redundant with instance risk under the
symbol-scoped model, but named explicitly for clarity — one
instance owns exactly one symbol)

Maximum simultaneous trades (this instance)

Daily / Weekly / Monthly instance risk budget

None of the above requires visibility into another symbol or
another Quantum instance. If a limit cannot be computed from this
instance's own configuration and this instance's own trade
history, it does not belong in this section — see DEFERRED / OUT
OF SCOPE.

==================================================================

OUTPUT: RiskState

Produce the RiskState object defined in
Contracts/Shared Data Objects.md — conceptually:

struct RiskState
{
    bool     approved;

    double   lotSize;

    double   riskAmount;

    double   stopPrice;

    double   targetPrice;

    ENUM_REJECTION_REASON rejectionReason;   // valid only if !approved

    ulong    sourceDecisionRef;              // the TradeDecision evaluated
};

RiskState is logged in full at creation — an approval and a
rejection are equally reconstructable after the fact.

==================================================================

API

Provide

Initialize()

ValidateTrade()

CalculatePositionSize()

DeriveStopLoss()

DeriveTakeProfit()

Reset()

No global variables.

No hidden dependencies.

This engine does not expose position-management methods
(UpdateStops, ManagePosition, ClosePosition, etc.) — those belong
to Part B's API.

==================================================================

CONFIGURATION

User configurable

Risk percentage

Maximum exposure

Daily loss (instance)

Weekly loss (instance)

ATR multipliers

Stop models

Target models

Maximum trades (instance)

Instance risk budget thresholds

==================================================================

ERROR HANDLING

Gracefully handle

Margin changes

Trading disabled

Broker requirement changes

Invalid or stale MarketContext at validation time

==================================================================

UNIT TESTING

Provide isolated tests for

Position sizing

Risk calculation

ATR Stop

Structure Stop

Instance risk limits

Instance drawdown protection (pre-trade check)

==================================================================

INTEGRATION

Consumes outputs from

Trade Quality Index (TradeDecision)

Market Regime Engine, HTF Bias Engine, Liquidity Engine,
Institutional Zones Engine, Temporal Context Engine (as inputs
already aggregated into the TradeDecision's evidence bundle — the
Risk Engine does not re-derive them)

Account state (equity, margin, balance) via the Platform Layer

Produces outputs to

Execution Engine (RiskState — the only downstream consumer)

Dashboard, Analytics (read-only)

The Risk Engine does not consume outputs from the Execution
Engine. The dependency runs one direction only: Execution depends
on Risk, not the reverse (SYSTEM_ARCHITECTURE.md Section 9). If a
future design needs the Execution Engine to report back to Risk
before a fill (e.g. actual fill price differs materially from the
RiskState's assumptions), that is Part B's job to detect and
handle post-fill, not a reason to create a Risk↔Execution cycle.

==================================================================
PART B — POSITION LIFECYCLE ENGINE
==================================================================

OBJECTIVE

Design and implement an institutional-grade Position Lifecycle
Engine in pure MQL5.

This engine receives an already-filled position (via
OnPositionOpened, referencing the RiskState and TradeDecision that
produced it) and manages it from that point through final close:
protective order placement, active monitoring, adaptive
management, exit optimization, and performance recording.

It MUST NOT decide whether to trade, and MUST NOT size a position
— that is Part A's job, already finished by the time this engine
sees the trade.

It MUST be able to reconstruct a position's state after a restart
without assuming it was told about that position in-session — see
RESTART RECOVERY below.

==================================================================

ENGINEERING PRINCIPLES

Follow SOLID principles.

Single Responsibility Principle.

Only manage already-filled positions.

Do NOT

Detect liquidity, HTF bias, order blocks, or sessions (upstream
engines' job)

Calculate TQI or generate entries (upstream)

Size a new position or approve/reject a trade (Part A's job)

Coordinate with, or assume visibility into, another symbol or
another Quantum instance (ADR-001, Sections 12–15)

==================================================================

DESIGN PHILOSOPHY

Every position passes through a complete lifecycle after fill:

Broker Fill Confirmed (OnPositionOpened)

↓

Position Discovery / State Construction

↓

Active Monitoring

↓

Adaptive Management

↓

Exit Optimization

↓

Performance Recording

↓

Statistics Engine

Restart Recovery re-enters this lifecycle at "Position Discovery"
for any position already open when the instance (re)initializes —
see RESTART RECOVERY.

==================================================================

TRADE MANAGEMENT

Support

Break-even

Partial Close

Trailing Stop

ATR Trailing

Structure Trailing

Liquidity Trailing

Step Trailing

Adaptive Trailing

Profit Lock

Time Stop

Volatility Exit

==================================================================

POSITION MONITORING

Continuously monitor

Current Profit

Current Loss

Maximum Favorable Excursion (MFE)

Maximum Adverse Excursion (MAE)

Current Drawdown (this position's own)

Current R-Multiple

ATR

Spread

Volatility

Market Regime Change

HTF Bias Change

Liquidity Events

Session Changes

==================================================================

ADAPTIVE MANAGEMENT

The engine may modify active trades based on

Market Regime changes

Session changes

Volatility expansion

Volatility contraction

Liquidity sweeps

Structure changes

Broker conditions

Learning Engine recommendations

==================================================================

EXIT OPTIMIZATION

Evaluate multiple exit reasons

Target reached

Stop Loss reached

Trailing exit

Structure failure

Risk violation

Time expiration

Volatility collapse

Execution degradation

Emergency exit

Each exit should record its reason.

==================================================================

INSTANCE DRAWDOWN CONTROL

Scoped to this instance's own open-position exposure and closed-
trade equity curve only — never account-wide (ADR-001, Section
14.1). This is the open-position-monitoring counterpart to the
pre-trade "Instance drawdown limit" check in Part A.

Implement

Soft drawdown limit

Hard drawdown limit

Trading cooldown (this instance)

Recovery mode (this instance)

Reduced risk mode (this instance — communicated to Part A via
Configuration, not via a direct call)

Capital preservation mode (this instance)

Automatic trading suspension (this instance)

==================================================================

POSITION QUALITY / POSITION HEALTH ENGINE

Calculate

Risk Quality

Management Quality

Exit Quality

Execution Efficiency

Capital Efficiency

Position Health

Normalize 0–100.

Rather than treating an open trade as simply "open" or "closed,"
continuously score its health from the inputs that are still
available while it's open:

Inputs

Market Regime still aligned?

HTF Bias still aligned?

Liquidity still favorable?

Institutional Zone still valid?

Session still favorable?

Spread acceptable?

Volatility acceptable?

Trade age

Current MAE / MFE

Distance to target / stop

Instance risk budget remaining

Example progression across a trade's life:

Health 94 — Trend still valid (YES), Liquidity Favorable, Session
London, Spread Excellent → Recommendation: Continue Holding

Health 41 — Trend Weakening, Liquidity Target consumed, Session NY
Close, Spread Widening → Recommendation: Reduce Exposure

Health 18 — Structure Broken, Liquidity Consumed, Volatility
Collapsed → Recommendation: Exit Immediately

This turns trade management from a collection of isolated rules
into a continuous evaluation: not "has price hit my trailing
stop?" but "given everything currently known about this position,
is it still healthy to keep capital allocated here?"

==================================================================

RESTART RECOVERY

Formal requirement, per ADR-001 Section 17.1 and Contracts/Shared
Data Objects.md (PositionState). This is a contract requirement,
not merely the "Restart recovery" / "Platform restart" / "Chart
refresh" test cases already listed in Prompt 12 — those test
against the behavior defined here.

On OnInit:

Resolve Instance Identity (RuntimeIdentity: Symbol, StrategyID,
InstanceID, MagicNumber)

↓

Discover broker-side positions filtered by Symbol + MagicNumber

↓

For each match, reconstruct PositionState from broker truth
(PositionTicket, open price, volume, current stop, current
target) — do not assume any in-memory record exists

↓

Attempt to resolve each reconstructed position's originating
RiskState / TradeDecision from this instance's own logged
history

↓

If no originating record is found: log the position as orphaned
state and surface it via Observability. Do not silently adopt it
into normal management, and do not silently ignore it — the exact
recovery action is an implementation decision, but the position
must not disappear from view.

↓

Resume normal Active Monitoring / Adaptive Management for every
recovered position

A position matching this instance's Symbol but not its
MagicNumber is never touched, whether or not an in-memory record
exists.

If this instance's configuration has changed since a still-open
position was opened, that position's broker-side state (stop,
target, size) remains authoritative; the new configuration governs
future decisions, not this already-open position, unless a
specific engine is explicitly designed to re-apply new parameters
retroactively.

==================================================================

OUTPUT STRUCTURES

Provide standardized outputs.

Example

struct PositionAnalysis
{
    ulong ticket;

    double riskScore;

    double managementScore;

    double healthScore;

    double mfe;

    double mae;

    double currentR;

    double remainingRisk;

    ENUM_EXIT_REASON recommendedExit;

    bool protected;

    bool valid;

    datetime lastUpdate;
};

==================================================================

API

Provide

Initialize()

RecoverOnRestart()

OnPositionOpened() / DiscoverPosition()

MonitorPosition()

UpdateStops()

UpdateTargets()

ManagePosition()

EvaluateExit()

ClosePosition()

GetPositionAnalysis()

Reset()

No global variables.

No hidden dependencies.

This engine does not expose pre-trade sizing/validation methods —
those belong to Part A's API.

==================================================================

CONFIGURATION

User configurable

Trailing parameters

Break-even rules

Partial close rules

Instance drawdown thresholds

Recovery mode thresholds

Cooldown duration

==================================================================

PERFORMANCE

Designed for

Millions of backtest ticks

Minimal CPU usage

Incremental updates

Cached position information

Reusable structures

Memory efficient

==================================================================

LOGGING

Optional detailed logging.

Example

[Position Lifecycle]

Trade

BUY

Ticket

3849217

Risk

0.75%

ATR Stop

1.28415

Break-even

Activated

Trailing

Structure

Current R

2.3

MFE

3.1R

MAE

0.4R

Exit Recommendation

Trail

==================================================================

VISUALIZATION

Optional chart display

Current Stop

Current Target

Trailing Line

Break-even Marker

Risk Box

Position Health

Current R

Remaining Risk

==================================================================

ERROR HANDLING

Gracefully handle

Rejected modifications

Broker restrictions

Margin changes

Trading disabled

Invalid tickets

Partial fills

Slippage

Network delays

Positions discovered during Restart Recovery that cannot be
resolved to an originating decision (see RESTART RECOVERY)

==================================================================

UNIT TESTING

Provide isolated tests for

Trailing logic

Break-even

Partial close

Exit evaluation

Instance drawdown protection (in-position)

Restart recovery / position reconstruction (including the
orphaned-position case)

==================================================================

INTEGRATION

Consumes

OnPositionOpened from Execution Engine (confirmed fill, with
reference to RiskState/TradeDecision)

Fresh MarketContext snapshots for ongoing management (does not
re-litigate the original qualifying evidence — that decision was
already made and logged by Part A)

Learning Engine recommendations (advisory)

Produces

OnPositionClosed → Statistics Engine

PositionState → Dashboard, Analytics

==================================================================

DELIVERABLES (Part A and Part B)

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

Production-ready institutional-quality MQL5.

The implementation must prioritize

Capital preservation

Execution reliability

Risk-adjusted performance

Scalability

Maintainability

Computational efficiency

==================================================================

DEFERRED / OUT OF SCOPE (ADR-001)

The following appeared in an earlier draft of this module and are
explicitly deferred — recorded here so the historical intent is
not lost, not implemented, and not silently reintroduced by a
future contributor who finds the concept familiar:

Portfolio Risk Allocation (position sizing that spans multiple
instances)

Cross-symbol / cross-currency correlation estimation and
correlation thresholds ("estimate correlation between symbols,
currencies, open positions")

Sector exposure, currency exposure, net directional exposure
across instances

Account-wide (cross-instance) daily / weekly / monthly loss
coordination — as distinct from this instance's own daily/weekly
loss and risk budget, which Part A does track

Cross-instance position netting or centralized portfolio
allocation

None of the above may be implemented inside the Risk Engine or the
Position Lifecycle Engine. Reintroducing any of it requires a
dedicated future architectural extension and its own ADR (ADR-001,
Sections 15 and 33), including a defined mechanism for how a
symbol-scoped instance would obtain visibility into another
instance's state in the first place — no such mechanism exists
today, and none of the "Prohibited Cross-Instance Communication"
mechanisms in ADR-001 Section 16 may be used to build one quietly.