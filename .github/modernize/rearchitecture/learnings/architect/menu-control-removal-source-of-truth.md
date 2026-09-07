# Menu Control Removal Source Of Truth

When UI removal is requested, treat current source and runtime from fresh build as authoritative before deleting controls.

## What Happened

In Nexus task t1, the requested legacy controls (Desktop App Grid, Smart Fit, Fixed Grid, Position Left/Center/Right) were not present in current source. The right architect output was a no-op removal contract plus runtime validation guidance, not speculative code changes.

## Takeaway

For brownfield UI cleanup tasks, first verify string/control presence in source and control wiring in the hosting layer. If absent, document a no-reintroduction contract and route runtime residue checks to testing.

## History

- 2026-09-01 (Nexus/t1): initial
