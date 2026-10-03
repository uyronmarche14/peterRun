# L01 v11 journey-layer source

These eight high-resolution image-generation sources are editable production inputs, not runtime art. The four approved V09 stage plates remain the geometry and road authority. `code/tools/export_l01_v11_journey_layers.gd` resizes the sources to a fixed 960×540 canvas, extracts seven aligned PNG layers per stage, and keeps the painted road and side-street pixels from the approved plates. Runtime exports live only in `code/art/backgrounds/l01_journey_v11_layers/`.

## Final generation prompt set

Each stage used the corresponding V09 plate as an image reference. The source-generation prompts were:

1. Waiting underpaint: “Precise object edit of the L01 Waiting Shed plate. Remove the near left and right buildings, waiting shed, street furniture, people, plants, poles and fences while keeping the central Barangay Hall, market, sun, mountains, road perspective, curbs and lane markings registered. Paint coherent distant rooftops, low vegetation and quiet paved verges in the exposed areas. Warm early-morning Filipino barangay illustration; no text or UI.”
2. Sari-sari underpaint: “Precise object edit of the L01 Sari-sari plate. Remove near left and right homes, shop frontage, people, street furniture, plants, poles and fences; preserve the central Hall, market, sky direction, mountains, road perspective, curbs and lanes. Fill revealed sides with coherent distant barangay rooftops, vegetation and paved verges. Late-morning daylight; no text or UI.”
3. Palengke underpaint: “Precise object edit of the L01 Palengke plate. Remove near market-side stalls, awnings, people, benches, street furniture, plants and surrounding buildings; keep the central Hall and market wing, sun, mountains, road, curbs and lane geometry registered. Extend plausible distant rooftops, vegetation and paved verges behind the removed sides. Warm early-afternoon illustration; no text or UI.”
4. Plaza underpaint: “Precise object edit of the L01 Plaza plate. Remove near left and right arcades, homes, stalls, people, lights and foreground plants; retain the central Hall/market, plaza paving, sunset direction, mountains, road, curbs and lanes. Fill exposed sides with coherent distant vegetation, rooftops and plaza verges. Golden-afternoon Filipino community arrival; no text or UI.”
5. Waiting sky: “Opaque sky-only 16:9 backplate. Soft Philippine early-morning blue-to-cream gradient, sparse cream clouds, restrained sun at the upper right. Extend the sky to the bottom edge for layered compositing. No land, buildings, trees, road, people, text, UI or border.”
6. Sari-sari sky: “Opaque sky-only 16:9 backplate. Calm late-morning Philippine blue sky with light white clouds and subtle warm sunlight. Extend the sky to the bottom edge for layered compositing. No land, buildings, trees, road, people, text, UI or border.”
7. Palengke sky: “Opaque sky-only 16:9 backplate. Warm early-afternoon Philippine sky, blue above fading to pale cream near the horizon, soft clouds mainly right, restrained upper-right sun. Extend to the bottom edge. No land, buildings, trees, road, people, text, UI or border.”
8. Plaza sky: “Opaque sky-only 16:9 backplate. Welcoming golden-afternoon Philippine sky, mango and apricot near the horizon, quieter teal-blue above, softly glowing upper-right sun, sparse gentle clouds. Extend to the bottom edge. No land, buildings, trees, road, people, text, UI or border.”

All prompts used an original polished illustrated 2.5D game-art finish. The source artwork is not copied from a commercial runner. Its exact horizon and curb pixels are **not** trusted for gameplay: the original stage road and `L01VisualGeometry` control alignment.

## Build and registration

Run from the project root:

`C:\Users\Rhyss\Downloads\Godot_v4.7.2-stable_win64_console.exe --headless --path code -s res://tools/export_l01_v11_journey_layers.gd`

Then run Godot's editor import once before the headless tests. Every layer and prepared roadside module is a 960×540 top-left-aligned image. The native game canvas is 480×270, so stage nodes scale uniformly to 0.5. Painted curb checkpoints in native pixels are approximately `(101,381)` at y=190, `(66,416)` at y=210, and `(52,429)` at y=218. The V09 road pixels are retained at all center-lane samples; prompt/lane behavior is unchanged.

The twenty transparent side modules are *prepared source cutouts* with registered contact points and clean underpaint available behind them. They are not yet animated in Godot. They support a future shallow, tested parallax pass; they should not be translated by a full building width or independently resized without first reviewing edge gaps and curb contact. Home continues to render its approved v10 seven-layer scene; only its roadside module cutouts were added here.
