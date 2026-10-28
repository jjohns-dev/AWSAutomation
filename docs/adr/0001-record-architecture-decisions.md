# ADR 1: Record architecture decisions

## Status

Accepted — 2026-10-28

## Context

- Decisions that shape this module, such as how dependencies are versioned, have been settled in issue threads, PR comments and chat.
- That reasoning cannot be found from the repository. A contributor reading `Build/depend.psd1` later sees the outcome but not the forces, so they can only accept it blindly or reverse it blindly.
- `AGENTS.md` and `CONTRIBUTING.md` document how to work in the repo, not why it is shaped the way it is.

## Decision

- We will record architecturally significant decisions as Architecture Decision Records under `docs/adr/NNNN-short-title.md`, in Michael Nygard's format: Title, Status, Context, Decision, Consequences.
- Records are numbered monotonically, never deleted, and never silently rewritten. A reversal or partial change is a new ADR that supersedes or amends the old one.
- We will write sections as concise bullets rather than prose paragraphs.
- Deviation from Nygard: the Status line carries the ISO date the current status took effect, e.g. `Accepted — 2026-10-28`.

## Consequences

- The reasoning behind a decision lives next to the code it governs and is reviewed in the same PR.
- Each architecturally significant change now carries the cost of writing a record, and deciding what counts as significant is a judgement call.
- Nothing mechanically enforces the format; a record with an all-upside Consequences section or Context written as justification is caught only by review.
