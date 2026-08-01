# ADR-002: Core stays a client library; orchestration is out-of-tree

- Status: Accepted
- Date: 2026-08

## Decision

Agent loops, multi-step planning, and conversation memory management are explicitly out of scope for the core package. If built at all, they ship as a separate dependent package.

## Alternatives considered

Building orchestration in from the start, matching LangChain's scope.

## Why rejected

This is the highest-leverage scope decision in the project. Every dependent extension that only needs “call this model, get structured JSON back” would carry the weight (compile time, object ID budget, cognitive surface area) of an agent framework it never uses. AL extensions have real object ID budget and dependency-chain compile costs that don't exist in npm/pip — a bloated core dependency is a heavier tax in AL than in JavaScript.

## Cost of this decision

Slower path to feature parity with LangChain-style frameworks, and a risk the orchestration layer never gets built by anyone. Accepted, because a fragmented orchestration layer atop a solid client layer beats a bloated, rarely-fully-used core.
