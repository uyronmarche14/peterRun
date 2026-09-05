# PETER RUN — Asset Register Template

> **Update this register whenever an asset is created, changed, approved, or connected to Godot.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## Status values

`BRIEF` → `CONCEPT` → `PIXEL_FINAL` → `IMPORTED` → `TESTED` → `APPROVED`

Use `BLOCKED` when waiting for a decision, input, licence review, or clinical/safety approval.

## Asset register

| Asset ID | Type | Level | Logical action | Source file | Final PNG/scene path | Native size / frames | Owner | Status | Licence/reference record | Godot test | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `char_player_base_v01` | Character | Shared | N/A | | | 48 × 64 / | | BRIEF | | | |
| `ui_icon_move_v01` | UI icon | Shared | move_left/right | | | 32 × 32 | | BRIEF | | | |
| `ui_icon_jump_v01` | UI icon | Shared | jump | | | 32 × 32 | | BRIEF | | | |
| `ui_icon_slide_v01` | UI icon | Shared | slide | | | 32 × 32 | | BRIEF | | | |
| `prompt_l01_delivery_crates_v01` | Prompt prop | L01 | move_left/right | | | 48 × 48 | | BRIEF | | | |
| `prompt_l01_curb_v01` | Prompt prop | L01 | jump | | | 64 × 32 | | BRIEF | | | |
| `prompt_l01_laundry_line_v01` | Prompt prop | L01 | slide | | | 64 × 48 | | BRIEF | | | |
| `env_l01_barangay_master_v01` | Environment | L01 | N/A | | | 480 × 270 | | BRIEF | | | |

## Level completion check

For each level, verify all rows below are `APPROVED` before treating its visual kit as finished.

| Required group | L01 | L02 | L03 | L04 | L05 |
| --- | --- | --- | --- | --- | --- |
| Background layers | ☐ | ☐ | ☐ | ☐ | ☐ |
| Path / lane readability | ☐ | ☐ | ☐ | ☐ | ☐ |
| Move prompt prop | ☐ | ☐ | ☐ | ☐ | ☐ |
| Jump prompt prop | ☐ | ☐ | ☐ | ☐ | ☐ |
| Slide prompt prop | ☐ | ☐ | ☐ | ☐ | ☐ |
| Decorative prop kit | ☐ | ☐ | ☐ | ☐ | ☐ |
| Summary/completion art | ☐ | ☐ | ☐ | ☐ | ☐ |
| Godot level resource hookup | ☐ | ☐ | ☐ | ☐ | ☐ |
| Readability/safety test | ☐ | ☐ | ☐ | ☐ | ☐ |

## Change log

| Date | Asset ID / document | Change | Reason | Approved by |
| --- | --- | --- | --- | --- |
| | | | | |
