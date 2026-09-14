# Peter Run Blender MCP

This local bridge connects Codex to Blender only for Peter Run sprite-source work. It binds to `127.0.0.1:9876` and exposes five safe operations: status, create the original Peter source model, pose an approved animation, render PNG frames, and validate those frames.

It does not expose arbitrary Python execution, internet access, asset downloads, arbitrary file paths, or access to other Blender files.

## One-time Blender setup

1. In Blender 5.2, open the Scripting workspace.
2. Open `addon/peter_run_blender_bridge.py` and press **Run Script**.
3. In the 3D Viewport sidebar, open the **Peter Run** tab and choose **Start Peter Run Bridge**.

## One-time Codex setup

Install the Node dependencies, then register `node server.mjs` as a stdio MCP server with this folder as its working directory.

The bridge renders source frames at 192 x 256 pixels to `generated/<animation>/`. Review and clean them in Pixelorama before importing final 48 x 64 PNG frames into Godot.
