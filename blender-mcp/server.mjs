import { McpServer } from "@modelcontextprotocol/server";
import { serveStdio } from "@modelcontextprotocol/server/stdio";
import { z } from "zod/v4";

const BRIDGE_URL = "http://127.0.0.1:9876/command";
const ANIMATIONS = ["idle", "run", "lane_left", "lane_right", "jump", "slide", "land", "success"];

async function sendCommand(command, payload = {}) {
  let response;
  try {
    response = await fetch(BRIDGE_URL, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ command, ...payload }),
      signal: AbortSignal.timeout(120_000)
    });
  } catch (error) {
    throw new Error("Cannot reach the Peter Run Blender bridge. In Blender, install the add-on and click Start Peter Run Bridge. " + error.message);
  }
  const body = await response.json().catch(() => ({ ok: false, error: "Bridge returned invalid JSON." }));
  if (!response.ok || !body.ok) {
    throw new Error(body.error || `Blender bridge request failed (${response.status}).`);
  }
  return body;
}

function result(payload) {
  return {
    content: [{ type: "text", text: JSON.stringify(payload, null, 2) }],
    structuredContent: payload
  };
}

function toolError(error) {
  return { content: [{ type: "text", text: error instanceof Error ? error.message : String(error) }], isError: true };
}

const server = new McpServer({ name: "peter-run-blender", version: "0.1.0" });

server.registerTool("blender_status", {
  title: "Check Peter Run Blender bridge",
  description: "Checks the local Blender 5.2 bridge before creating or rendering Peter assets."
}, async () => {
  try { return result(await sendCommand("status")); } catch (error) { return toolError(error); }
});

server.registerTool("create_peter_character", {
  title: "Create original Peter source character",
  description: "Creates or safely replaces only the PETER_RUN_GENERATED collection with an original back-facing Peter source model."
}, async () => {
  try { return result(await sendCommand("create_character")); } catch (error) { return toolError(error); }
});

server.registerTool("pose_peter", {
  title: "Pose Peter animation",
  description: "Creates a deterministic animation for one approved Peter movement. It never changes Godot gameplay logic.",
  inputSchema: z.object({ animation: z.enum(ANIMATIONS) })
}, async ({ animation }) => {
  try { return result(await sendCommand("pose", { animation })); } catch (error) { return toolError(error); }
});

server.registerTool("render_peter_animation", {
  title: "Render Peter animation frames",
  description: "Renders transparent PNG frames at 192 by 256 into this bridge's generated folder for Pixelorama cleanup.",
  inputSchema: z.object({ animation: z.enum(ANIMATIONS) })
}, async ({ animation }) => {
  try { return result(await sendCommand("render", { animation })); } catch (error) { return toolError(error); }
});

server.registerTool("validate_peter_export", {
  title: "Validate Peter render export",
  description: "Checks the generated PNG frames for the selected approved animation and reports their dimensions and count.",
  inputSchema: z.object({ animation: z.enum(ANIMATIONS) })
}, async ({ animation }) => {
  try { return result(await sendCommand("validate", { animation })); } catch (error) { return toolError(error); }
});

await serveStdio(() => server);
