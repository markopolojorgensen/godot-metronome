extends Node2D

# Project Settings -> Audio -> Driver -> Output Latency

var time_begin := 0.0
var time_left := 0.0
var interval := 100000.0
var interval_sum := 0.0

var bpm = 120.0

var start_bpm = 90.0
var end_bpm = 180.0
var tween_bpm = 120.0
var tween_duration = 500.0
var tween: Tween

var primary = true

# Called when the node enters the scene tree for the first time.
func _ready():
	reset_tween()
	
	get_window().title = "Metronome %s" % ProjectSettings.get_setting("application/config/version")


func _physics_process(_delta):
	# https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html
	var time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	
	var time = (Time.get_ticks_usec() - time_begin) / 1_000_000.0
	time += time_delay
	%TimeElapsedLabel.text = "%.2f" % time
	
	if interval_sum <= time:
		if primary:
			$CustomAudio.play()
		else:
			$CustomAudio2.play()
		primary = not primary
		
		interval = 60.0 / tween_bpm
		interval_sum += interval
		%BPMLabel.text = "Current BPM: %.1f" % tween_bpm

func _on_load_audio_1_button_pressed():
	load_custom_audio_stream($CustomAudio)

func _on_load_audio_2_button_pressed():
	load_custom_audio_stream($CustomAudio2)

func load_custom_audio_stream(asp: AudioStreamPlayer):
	var fd = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.access = FileDialog.ACCESS_FILESYSTEM
	fd.use_native_dialog = true
	fd.file_selected.connect(func(file):
		print(file)
		match (file as String).get_extension():
			"ogg":
				asp.stream = AudioStreamOggVorbis.load_from_file(file)
			_:
				print("Failed to load %s, unknown file extension '%s'" % [file, file.get_extension()])
		)
	add_child(fd)
	fd.popup_centered(Vector2i(1152, 648) * 0.9)


func _on_start_spin_box_value_changed(value):
	start_bpm = value
	reset_tween()

func _on_end_spin_box_value_changed(value):
	end_bpm = value
	reset_tween()

func _on_duration_spin_box_value_changed(value):
	tween_duration = value
	reset_tween()

func reset_tween():
	if tween:
		tween.kill()
	tween = create_tween()
	
	tween_bpm = start_bpm
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "tween_bpm", end_bpm, tween_duration)
	
	time_begin = Time.get_ticks_usec()
	interval_sum = 0.0


