extends SceneTree
## Captures the real player/controller and level. No pasted character overlays.
const OUTPUT := "res://../test_evidence/peter_original_v01"
const SIZES := [Vector2i(960,540),Vector2i(1024,768),Vector2i(1920,1080)]
var level: Node
var player: Node
var entries: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		printerr("Actual graphical viewport required")
		quit(2)
		return
	root.mode=Window.MODE_WINDOWED
	root.borderless=true
	root.position=Vector2i.ZERO
	root.size=Vector2i(960,540)
	root.title="PETER RUN - Original Peter verification"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	level=load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	for timer in level.get_node("PromptTimers").get_children(): timer.stop()
	player=level.get_node("Player")
	if "--record" in OS.get_cmdline_user_args():
		await record_sequence()
	else:
		await capture_poses()
		if entries.size()!=39:
			printerr("Incomplete graphical capture")
			quit(1)
			return
	var report_name="record_report.json" if "--record" in OS.get_cmdline_user_args() else "captures.json"
	var report=FileAccess.open(OUTPUT+"/"+report_name,FileAccess.WRITE)
	report.store_string(JSON.stringify(entries,"\t"))
	level.free()
	print("PETER ORIGINAL GRAPHICAL CAPTURE PASS: ",entries.size())
	quit(0)

func capture_poses() -> void:
	player.set_process(false)
	for size in SIZES:
		root.size=size
		await process_frame
		await process_frame
		for action in [&"idle_ready",&"walk_forward",&"move_left",&"move_right",&"jump",&"slide",&"rest"]:
			player.reset_for_practice()
			match action:
				&"walk_forward": player.set_walking(true)
				&"rest": player.set_resting_preview()
				&"idle_ready": pass
				_: player.handle_action(action)
			step(.11 if action in [&"move_left",&"move_right"] else (.24 if action==&"slide" else .30))
			player.set_gameplay_paused(true)
			await capture(String(action),size)
			if action in [&"jump",&"slide",&"move_left"]:
				level.pause_gameplay()
				await process_frame
				await capture(String(action)+"_paused",size)
				level.resume_gameplay()
				step(.035)
				player.set_gameplay_paused(true)
				await capture(String(action)+"_resumed",size)

func step(seconds: float) -> void:
	for key in [&"_lane_tween",&"_action_tween",&"_shadow_tween"]:
		var tween: Tween=player.get(key)
		if tween!=null and tween.is_valid():
			tween.pause()
			tween.custom_step(seconds)
	player._process(seconds)

func capture(label: String,size: Vector2i) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	var name="%s_%dx%d.png" % [label,size.x,size.y]
	var method="viewport_readback"
	if image.get_size()!=size:
		# Canvas-items stretch keeps the 16:9 game viewport and adds letterbox
		# bars at 4:3. Reconstruct only those bars from the real viewport pixels;
		# never read another desktop window into verification evidence.
		var window_image:=Image.create_empty(size.x,size.y,false,image.get_format())
		window_image.fill(Color.BLACK)
		var inset:=Vector2i((size.x-image.get_width())/2,(size.y-image.get_height())/2)
		window_image.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),inset)
		image=window_image
		method="viewport_readback_with_letterbox_canvas"
	assert(image.save_png(OUTPUT+"/"+name)==OK)
	assert(image.get_size()==size,"Evidence must match requested dimensions")
	entries.append({"file":name,"capture_method":method,"viewport":[image.get_width(),image.get_height()],"clip":String(player.character_sprite.animation),"frame":player.character_sprite.get_clip_frame(),"elapsed":player.character_sprite.elapsed,"position":[player.position.x,player.position.y]})

func record_sequence() -> void:
	# Use --fixed-fps 30 --write-movie <path>. Godot records actual rendered frames.
	player.reset_for_practice()
	player.set_walking(true)
	var events := {30:&"move_left",55:&"move_right",85:&"jump",130:&"slide",175:&"jump",240:&"slide"}
	var frame_times: Array[float]=[]
	for index in 300:
		var before=Time.get_ticks_usec()
		if events.has(index):
			var action: StringName=events[index]
			level.receive_input(action,true,index/30.0)
			level.receive_input(action,false,index/30.0+.001)
		if index==182 or index==245: level.pause_gameplay()
		if index==212 or index==267: level.resume_gameplay()
		await process_frame
		frame_times.append((Time.get_ticks_usec()-before)/1000.0)
	entries.append({"recording":"300 real viewport frames at fixed 30 fps","sequence":"walk, left, right, jump, duck, jump pause/resume, duck pause/resume","fixed_step_capture":true,"mean_wall_ms_including_capture":frame_times.reduce(func(a,b):return a+b,0.0)/frame_times.size(),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
