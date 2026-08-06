You are a senior quantitative software engineer and MQL5 architect with expertise in institutional trading systems.

Your task is NOT to improve the trading strategy yet.

Your ONLY objective is to completely redesign the software architecture of the existing EA into a modular, scalable, enterprise-level codebase while preserving the current trading behavior.

This is an architectural refactoring task, NOT a strategy modification task.

=========================================================
PRIMARY GOALS
=========================================================

1. Keep the existing trading logic producing identical signals.
2. Do NOT change strategy rules.
3. Do NOT change entry conditions.
4. Do NOT change exit conditions.
5. Do NOT change confidence scoring.
6. Do NOT change risk management.
7. Only reorganize and improve architecture.

=========================================================
TARGET ARCHITECTURE
=========================================================

Separate the EA into independent logical modules.

The architecture should resemble:

MarketRegimeEngine
InstitutionalBiasEngine
MarketStructureEngine
LiquidityEngine
OrderBlockEngine
FairValueGapEngine
SessionEngine
TradeQualityEngine
RiskManagementEngine
ExecutionEngine
StatisticsEngine
DashboardEngine
Utilities
Configuration

Each module must have a clearly defined responsibility.

Modules must communicate only through well-defined data structures.

Avoid hidden dependencies.

=========================================================
DATA FLOW
=========================================================

The EA should process data in this order:

Market Data
↓

Market Context

↓

HTF Bias

↓

Market Structure

↓

Liquidity

↓

Institutional Zones

↓

Entry Analysis

↓

Trade Decision

↓

Risk Management

↓

Execution

↓

Trade Statistics

↓

Dashboard

Each stage should receive structured information from the previous stage instead of recalculating everything.

=========================================================
DATA STRUCTURES
=========================================================

Replace scattered global variables with structured objects.

Design dedicated structs/classes such as:

MarketContext

StructureData

LiquidityData

OrderBlockData

FVGData

SessionData

EntrySignal

RiskParameters

TradeStatistics

DashboardData

Configuration

Each struct should contain only the fields relevant to its responsibility.

=========================================================
CODING STANDARDS
=========================================================

Follow institutional coding standards.

Use:

Consistent naming

Self-documenting code

Single Responsibility Principle

Minimal code duplication

Encapsulation

High cohesion

Low coupling

Avoid giant functions.

No function should exceed roughly 150 lines unless absolutely necessary.

Split large calculations into reusable helper functions.

=========================================================
CONFIGURATION
=========================================================

Move all user-adjustable parameters into clearly grouped sections.

Example:

Trade Settings

Risk Settings

Market Structure

Liquidity

Order Blocks

Fair Value Gaps

Sessions

Dashboard

Optimization

Debug

Every parameter should have meaningful comments.

=========================================================
ERROR HANDLING
=========================================================

Create centralized error handling.

Every broker operation should return detailed diagnostics.

Include:

Trade retcode

Broker message

Failed operation

Symbol

Time

Function name

=========================================================
LOGGING
=========================================================

Implement centralized logging.

Support levels:

INFO

WARNING

ERROR

DEBUG

Allow debug logging to be enabled or disabled through inputs.

=========================================================
PERFORMANCE
=========================================================

Optimize for low CPU usage.

Avoid unnecessary CopyBuffer calls.

Cache values whenever possible.

Avoid repeated indicator calculations.

Minimize memory allocations.

Process only new bars when appropriate.

=========================================================
EXTENSIBILITY
=========================================================

Design the architecture so future modules can be added without modifying existing modules.

Future modules will include:

Adaptive Learning Engine

Trade Quality Index

Premium/Discount Engine

SMT Divergence

Volume Imbalance

CRT Model

News Filter

Portfolio Manager

Regime Detection

These modules are NOT to be implemented now.

Only prepare the architecture.

=========================================================
BACKWARD COMPATIBILITY
=========================================================

The EA should compile and behave exactly like the current version after refactoring.

No trading behavior should change.

=========================================================
EXPECTED OUTPUT
=========================================================

Deliver a complete architectural refactoring.

Maintain identical trading logic.

Improve readability.

Improve maintainability.

Improve modularity.

Improve scalability.

Do NOT add new strategy concepts.

Do NOT optimize the strategy.

Do NOT modify signal generation.

Only redesign the software architecture to professional institutional standards.

The resulting code should become the foundation for all future development.