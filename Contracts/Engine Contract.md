# Engine Contract

Every engine in Project Quantum shall define the following (SYSTEM_ARCHITECTURE.md Section 7). This is the minimum standard every engine's contract must satisfy — it does not require an engine to implement methods it has no need for; it requires the contract to state, explicitly, where the engine stands on each point below.

- **Purpose** — one sentence stating what the engine exists to do.
- **Responsibilities** — the specific things the engine owns.
- **Non-Responsibilities** — the closely related work this engine explicitly does not do (its boundaries, SYSTEM_ARCHITECTURE.md Section 7).
- **Runtime Scope** — every engine is instance-scoped: it belongs to exactly one Quantum runtime instance (one Symbol, one Strategy ID, one Instance ID, one Magic Number — see Runtime Identity in `Shared Data Objects.md`). An engine may consume shared code and shared immutable definitions; it shall not assume access to another instance's runtime state (ADR-001).
- **Inputs** — the data the engine requires, and where it comes from.
- **Outputs** — the data the engine produces, in what structure, and who is permitted to consume it.
- **Dependencies** — the upstream engines/outputs this engine requires. No circular dependencies, direct or transitive (SYSTEM_ARCHITECTURE.md Section 9).
- **State Ownership** — which runtime state objects this engine owns exclusively, and which it only reads (SYSTEM_ARCHITECTURE.md Section 11).
- **Configuration** — which Configuration Engine parameters this engine reads, and whether each is instance-scoped or (if any exist in future) global-scoped.
- **Events Consumed** — which published events this engine reacts to (see `Event Definitions.md`).
- **Events Produced** — which events this engine publishes, and their scope.
- **Lifecycle** — how the engine behaves across `OnInit` / `OnTick` / `OnDeinit`. If the engine manages broker-side state (principally the Position Lifecycle Engine), this must state what it reconstructs from broker/terminal truth on restart, and what it treats as orphaned state (ADR-001, Restart Recovery; `Shared Data Objects.md`, PositionState).
- **Error Handling** — how the engine fails: logged, defined, non-silent (SYSTEM_ARCHITECTURE.md Section 13).
- **Testing Expectations** — how the engine can be exercised in isolation, against synthetic and historical data, without requiring the full platform running (SYSTEM_ARCHITECTURE.md Section 4.9).

No engine's Section 7 definition is complete until every point above is stated, even where the answer is "none."