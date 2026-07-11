# ADR 005: Local Receipt with Optional RunLedger Integration

## Context

Every run needs a structured receipt, while RunLedger is an independent local ecosystem CLI with its own schema and lifecycle.

## Decision

Write the complete Workcell receipt locally behind `src/receipts/receipt.kujo`. Keep future RunLedger integration at an adapter boundary and preserve Workcell's execution/verification/export/cleanup distinctions.

## Consequences

Workcell remains usable offline and without sibling package installation. A future adapter can publish the same evidence without duplicating or weakening the local contract.
