# PR-12 work status — 2026-09-07

Scope: BR-10 / FR-11 / build-queue PR-12. Load L01 and a second developer fixture through one runner with unchanged exercise targets, input mapping, fixed pace and timing.

Owner: Codex, sequential resource-contract, integration and verification work. No concurrent agent file ownership.

Work order:

1. Define validated level resources and an explicit catalog; extract existing prop geometry without changing it.
2. Integrate selected resource into runner, Ready, review snapshots and Retry; pool prop instances at scene load.
3. Verify both definitions, completion/miss/pause/early-end/retry routes and invalid data. Inspect rendered scenes. Update authoring handoff.

Contract/flow test: `code/tests/level_definition_test.gd`. Visual capture: `code/tests/support/capture_level_resources.gd`. Local evidence: `test_evidence/PR12_level_resources_validation.md`.

Verification status: implemented locally; all 20 automated test scripts passed, both resources rendered successfully, and the headless editor/import check passed. Human keyboard walkthrough, hardware, export and therapist UAT: not run.

Handoff: PR-13 adds actual L02–L05 content and normal level selection. PR-14 supplies final art. Do not represent the Courtyard Test fixture as a shipped level.

Documentation gap: `DECISIONS.md`, referenced by AGENT_TEAM, was absent on inspection. This record is a current implementation status, not a replacement clinical decision record. No new clinical targets, cadence or approvals were inferred. Therapist approval remains a deployment blocker.
