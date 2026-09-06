# PR-12 work status — 2026-09-07

## Current direction

PR-13, new themes and the route selector are deferred at the user's request. Maintain Barangay Morning as the only normal route. Current follow-up: clarify route wording and add an optional, non-scoring tutorial demonstration. Existing movement pace, response timing, input mappings and repetition targets are unchanged.

Future route choices, if resumed, are environment choices separate from therapist-controlled repetition settings; no difficulty ladder, unlocks or forced progression.

Current follow-up verification: implemented; 21 automated scripts passed and the compact UI capture completed without overflow. Inspected tutorial demo/pause and Setup route-label frames. Evidence: `test_evidence/single_route_tutorial_polish_validation.md`.

## PR-12 handoff record

Scope: BR-10 / FR-11 / build-queue PR-12. Load L01 and a second developer fixture through one runner with unchanged exercise targets, input mapping, fixed pace and timing.

Owner: Codex, sequential resource-contract, integration and verification work. No concurrent agent file ownership.

Work order:

1. Define validated level resources and an explicit catalog; extract existing prop geometry without changing it.
2. Integrate selected resource into runner, Ready, review snapshots and Retry; pool prop instances at scene load.
3. Verify both definitions, completion/miss/pause/early-end/retry routes and invalid data. Inspect rendered scenes. Update authoring handoff.

Contract/flow test: `code/tests/level_definition_test.gd`. Visual capture: `code/tests/support/capture_level_resources.gd`. Local evidence: `test_evidence/PR12_level_resources_validation.md`.

Verification status: implemented locally; all 20 automated test scripts passed, both resources rendered successfully, and the headless editor/import check passed. Human keyboard walkthrough, hardware, export and therapist UAT: not run.

Deferred handoff: PR-13 would add actual L02–L05 content and route selection if resumed. PR-14 supplies final art. Do not represent the Courtyard Test fixture as a shipped level.

Documentation gap: `DECISIONS.md`, referenced by AGENT_TEAM, was absent on inspection. This record is a current implementation status, not a replacement clinical decision record. No new clinical targets, cadence or approvals were inferred. Therapist approval remains a deployment blocker.
