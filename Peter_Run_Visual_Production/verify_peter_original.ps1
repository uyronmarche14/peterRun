param([string]$Godot = 'C:\Users\Rhyss\Downloads\Godot_v4.7.2-stable_win64_console.exe')
$project = Split-Path $PSScriptRoot -Parent
$evidence = Join-Path $project 'test_evidence/peter_original_v01'
$tests = @('project_setup_smoke','original_character_test','classic_sprite_test','classic_sprite_assets_test','classic_player_animation_test','classic_feedback_animation_test','player_controller_test','pause_motion_test','tutorial_demo_test','guided_tutorial_test','input_adapter_test','keyboard_gameplay_input_test','session_progress_test','session_summary_flow_test','contact_response_test','formation_response_integrity_test')
$results = @()
$tests += 'original_character_export_test'
foreach ($test in $tests) {
    $log = & $Godot --headless --path (Join-Path $project 'code') -s ('res://tests/'+$test+'.gd') 2>&1
    $status = $LASTEXITCODE
    $log | Out-File (Join-Path $evidence ($test+'.log')) -Encoding utf8
    $errors = @($log | Where-Object { "$_" -match 'SCRIPT ERROR|ERROR:|FAIL:' })
    $passed = $status -eq 0 -and $errors.Count -eq 0
    $results += [pscustomobject]@{test=$test; exit_code=$status; passed=$passed; errors=$errors.Count}
    Write-Output ($test+': '+$passed)
}
$results | ConvertTo-Json | Out-File (Join-Path $evidence 'godot_test_results.json') -Encoding utf8
if (@($results | Where-Object { -not $_.passed }).Count -gt 0) { exit 1 }
