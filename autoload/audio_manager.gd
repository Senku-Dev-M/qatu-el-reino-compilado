extends Node
## Audio sintetizado en tiempo de ejecución: efectos y música ambiental.
## Las pistas se generan en un hilo y se guardan en caché en user://.

const RATE := 22050
const CACHE_DIR := "user://audio_cache/"
const CACHE_VERSION := "v3"

var sfx: Dictionary = {}
var music_streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_track := ""
var _wanted_track := ""
var _generating := {}
var _mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
	if DisplayServer.get_name() == "headless":
		return
	_build_sfx()


# --- API --------------------------------------------------------------------------------

func play_sfx(name: String, pitch_var := 0.06) -> void:
	if not sfx.has(name):
		return
	var p: AudioStreamPlayer = null
	for candidate in _players:
		if not candidate.playing:
			p = candidate
			break
	if p == null:
		p = _players[0]
	p.stream = sfx[name]
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_music(track: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_wanted_track = track
	if track == _current_track:
		return
	_mutex.lock()
	var is_ready := music_streams.has(track)
	_mutex.unlock()
	if not is_ready:
		_generate_track_async(track)
		return
	_crossfade_to(track)


func _crossfade_to(track: String) -> void:
	_current_track = track
	var old_player := _music_a if _music_a.playing and _music_a.volume_db > -40.0 else _music_b
	var new_player := _music_b if old_player == _music_a else _music_a
	new_player.stream = music_streams[track]
	new_player.volume_db = -40.0
	new_player.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(new_player, "volume_db", 0.0, 2.0)
	if old_player.playing:
		tw.tween_property(old_player, "volume_db", -60.0, 2.0)
		tw.chain().tween_callback(old_player.stop)


# --- Síntesis básica -------------------------------------------------------------------------

func _to_stream(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = buf.size()
	return s


## Tono con barrido de frecuencia y envolvente.
func _tone(dur: float, f0: float, f1: float, wave := "sine", vol := 0.5, attack := 0.005, curve := 2.0, noise_mix := 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t * t * (3.0 - 2.0 * t))
		phase += f / RATE
		var v := 0.0
		match wave:
			"sine": v = sin(TAU * phase)
			"square": v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"saw": v = fmod(phase, 1.0) * 2.0 - 1.0
			"tri": v = absf(fmod(phase, 1.0) * 4.0 - 2.0) - 1.0
		if noise_mix > 0.0:
			v = lerpf(v, randf_range(-1.0, 1.0), noise_mix)
		var env := minf(1.0, float(i) / maxf(1.0, attack * RATE)) * pow(1.0 - t, curve)
		buf[i] = v * env * vol
	return buf


func _noise(dur: float, vol := 0.5, cutoff := 0.3, curve := 2.0, cutoff_end := -1.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var c := cutoff if cutoff_end < 0.0 else lerpf(cutoff, cutoff_end, t)
		lp += (randf_range(-1.0, 1.0) - lp) * c
		buf[i] = lp * vol * pow(1.0 - t, curve) * minf(1.0, i / 60.0)
	return buf


func _mix(a: PackedFloat32Array, b: PackedFloat32Array, offset := 0) -> PackedFloat32Array:
	var out := a.duplicate()
	if out.size() < b.size() + offset:
		out.resize(b.size() + offset)
	for i in b.size():
		out[i + offset] += b[i]
	return out


func _build_sfx() -> void:
	sfx.jump = _to_stream(_mix(_tone(0.12, 220, 440, "tri", 0.25), _noise(0.08, 0.15, 0.4)))
	sfx.land = _to_stream(_noise(0.12, 0.35, 0.12, 3.0))
	sfx.slash = _to_stream(_noise(0.16, 0.45, 0.7, 2.0, 0.08))
	sfx.hit = _to_stream(_mix(_tone(0.14, 180, 60, "sine", 0.6, 0.001, 3.0), _noise(0.08, 0.4, 0.5)))
	sfx.enemy_hit = _to_stream(_mix(_tone(0.12, 320, 90, "square", 0.22, 0.001, 3.0), _noise(0.1, 0.35, 0.45)))
	sfx.enemy_death = _to_stream(_mix(_tone(0.45, 400, 50, "saw", 0.25, 0.001, 2.0), _noise(0.4, 0.3, 0.25, 1.5, 0.05)))
	sfx.pogo = _to_stream(_mix(_tone(0.15, 500, 900, "tri", 0.25), _noise(0.06, 0.2, 0.6)))
	sfx.hurt = _to_stream(_mix(_tone(0.35, 300, 80, "saw", 0.35, 0.001, 1.5), _noise(0.3, 0.45, 0.35, 2.0)))
	sfx.death = _to_stream(_mix(_tone(1.2, 220, 40, "saw", 0.3, 0.01, 1.2), _noise(1.2, 0.35, 0.2, 1.0, 0.02)))
	sfx.heal_charge = _to_stream(_tone(0.5, 300, 600, "sine", 0.18, 0.2, 0.5))
	sfx.heal = _to_stream(_mix(_tone(0.6, 660, 660, "sine", 0.3, 0.005, 2.5), _tone(0.6, 990, 990, "sine", 0.18, 0.02, 2.5)))
	sfx.grapple = _to_stream(_mix(_tone(0.22, 300, 1400, "square", 0.14, 0.002, 1.0), _tone(0.22, 600, 2000, "sine", 0.18)))
	sfx.tablet = _to_stream(_mix(_tone(1.6, 110, 110, "sine", 0.5, 0.01, 2.0), _tone(1.6, 220.5, 220.5, "sine", 0.25, 0.01, 3.0)))
	var ok := _tone(0.25, 523, 523, "sine", 0.3)
	ok = _mix(ok, _tone(0.25, 659, 659, "sine", 0.3), int(0.1 * RATE))
	ok = _mix(ok, _tone(0.8, 784, 784, "sine", 0.3, 0.005, 2.0), int(0.2 * RATE))
	ok = _mix(ok, _tone(0.9, 1046, 1046, "sine", 0.2, 0.005, 2.0), int(0.3 * RATE))
	sfx.sello_ok = _to_stream(ok)
	sfx.sello_bad = _to_stream(_mix(_tone(0.35, 180, 150, "square", 0.14, 0.005, 1.5), _tone(0.35, 190, 158, "square", 0.12, 0.005, 1.5)))
	sfx.ui_move = _to_stream(_tone(0.05, 900, 900, "sine", 0.12, 0.001, 3.0))
	sfx.ui_open = _to_stream(_mix(_tone(0.25, 300, 600, "sine", 0.15), _noise(0.2, 0.12, 0.2)))
	sfx.ui_close = _to_stream(_tone(0.18, 600, 300, "sine", 0.12))
	sfx.type = _to_stream(_tone(0.03, 1200, 1100, "tri", 0.06, 0.001, 3.0))
	var gt := _tone(1.4, 392, 392, "sine", 0.3, 0.01, 1.5)
	gt = _mix(gt, _tone(1.3, 587, 587, "sine", 0.25, 0.01, 1.5), int(0.15 * RATE))
	gt = _mix(gt, _tone(1.2, 784, 784, "sine", 0.22, 0.01, 1.5), int(0.3 * RATE))
	sfx.item_get = _to_stream(gt)
	sfx.buy = _to_stream(_mix(_tone(0.12, 1200, 1200, "square", 0.1), _tone(0.3, 1600, 1600, "sine", 0.2), int(0.08 * RATE)))
	sfx.bits = _to_stream(_tone(0.08, 1500, 2100, "sine", 0.12, 0.001, 2.0))
	sfx.bench = _to_stream(_mix(_tone(1.5, 196, 196, "sine", 0.3, 0.1, 1.5), _tone(1.5, 294, 294, "sine", 0.2, 0.2, 1.5)))
	sfx.door = _to_stream(_noise(0.5, 0.35, 0.08, 1.0))
	sfx.gate_open = _to_stream(_mix(_noise(0.9, 0.4, 0.06, 1.0), _tone(0.9, 80, 60, "saw", 0.2)))
	sfx.area_title = _to_stream(_mix(_tone(3.0, 110, 110, "sine", 0.4, 0.5, 1.5), _tone(3.0, 164.8, 164.8, "sine", 0.25, 0.8, 1.5)))
	sfx.charm_on = _to_stream(_tone(0.2, 700, 1000, "sine", 0.2))
	sfx.charm_off = _to_stream(_tone(0.2, 1000, 700, "sine", 0.2))
	sfx.boss_roar = _to_stream(_mix(_tone(1.4, 90, 60, "saw", 0.4, 0.05, 1.0, 0.3), _noise(1.4, 0.4, 0.1, 1.0)))
	sfx.break_wall = _to_stream(_mix(_noise(0.6, 0.6, 0.15, 1.5, 0.03), _tone(0.4, 120, 40, "sine", 0.5)))
	sfx.shade = _to_stream(_mix(_tone(0.8, 150, 300, "sine", 0.2, 0.3, 1.0), _noise(0.8, 0.2, 0.05, 1.0)))
	sfx.node_on = _to_stream(_mix(_tone(0.3, 880, 880, "sine", 0.22, 0.001, 2.5), _tone(0.3, 1320, 1320, "sine", 0.12, 0.001, 3.0)))
	sfx.spit = _to_stream(_mix(_tone(0.15, 700, 300, "square", 0.12), _noise(0.12, 0.2, 0.5)))


# --- Música generativa -------------------------------------------------------------------------

func _generate_track_async(track: String) -> void:
	if _generating.has(track):
		return
	var cached := _load_cache(track)
	if cached.size() > 0:
		_on_track_ready(track, cached)
		return
	_generating[track] = true
	var task := func():
		var buf := _compose(track)
		call_deferred("_on_track_ready", track, buf, true)
	WorkerThreadPool.add_task(task, false, "music_" + track)


func _on_track_ready(track: String, buf: PackedFloat32Array, save := false) -> void:
	var stream := _to_stream(buf, true)
	_mutex.lock()
	music_streams[track] = stream
	_mutex.unlock()
	_generating.erase(track)
	if save:
		_save_cache(track, buf)
	if _wanted_track == track and _current_track != track:
		_crossfade_to(track)


func _cache_path(track: String) -> String:
	return CACHE_DIR + "%s_%s.bin" % [track, CACHE_VERSION]


func _load_cache(track: String) -> PackedFloat32Array:
	var path := _cache_path(track)
	if not FileAccess.file_exists(path):
		return PackedFloat32Array()
	var bytes := FileAccess.get_file_as_bytes(path)
	return bytes.to_float32_array()


func _save_cache(track: String, buf: PackedFloat32Array) -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	var f := FileAccess.open(_cache_path(track), FileAccess.WRITE)
	if f:
		f.store_buffer(buf.to_byte_array())


static func _midi(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)


func _compose(track: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(track)
	var seconds := 48.0
	var n := int(seconds * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	match track:
		"hub":
			# La menor pentatónica: quena melancólica sobre un bordón.
			_pad(buf, [45, 52, 57], 0.0, seconds, 0.07)
			var scale := [57, 60, 62, 64, 67, 69, 72, 74, 76]
			var t := 2.0
			var idx := 4
			while t < seconds - 4.0:
				idx = clampi(idx + rng.randi_range(-2, 2), 0, scale.size() - 1)
				var d: float = [1.0, 1.5, 2.0, 3.0][rng.randi() % 4]
				_flute(buf, _midi(scale[idx]), t, d * 0.95, 0.12)
				t += d + (rng.randf_range(0.5, 2.0) if rng.randf() < 0.25 else 0.0)
			for k in 12:
				_pluck(buf, _midi([45, 52, 57, 60][rng.randi() % 4]), rng.randf_range(0, seconds - 3.0), 0.08)
		"boss":
			_pad(buf, [38, 45, 50], 0.0, seconds, 0.08)
			var beat := 60.0 / 128.0
			var t := 0.0
			var step := 0
			while t < seconds - 0.2:
				if step % 4 == 0:
					_kick(buf, t, 0.45)
				if step % 8 == 6:
					_snare(buf, t, 0.18)
				if step % 2 == 1:
					_hat(buf, t, 0.05)
				var bass: int = [38, 38, 41, 36][int(step / 16.0) % 4]
				if step % 2 == 0:
					_bass(buf, _midi(bass), t, beat * 0.9, 0.16)
				t += beat * 0.5
				step += 1
			var lead := [62, 65, 64, 60, 62, 69, 67, 65]
			for k in lead.size() * 2:
				_flute(buf, _midi(lead[k % lead.size()]), 3.0 + k * beat * 4.0 * 0.75, beat * 2.5, 0.07)
		"canyon":
			# Cañones: bordón grave, charango pulsado en re dórico y percusión suave.
			_pad(buf, [38, 45, 50], 0.0, seconds, 0.06)
			var beat := 60.0 / 92.0
			var tb := 0.0
			var step := 0
			var riff := [62, 65, 67, 69, 67, 65, 64, 62]
			while tb < seconds - 1.0:
				if step % 4 == 0:
					_kick(buf, tb, 0.22)
				if step % 8 == 6:
					_hat(buf, tb, 0.08)
				if step % 2 == 0 and rng.randf() < 0.8:
					_pluck(buf, _midi(riff[(step / 2) % riff.size()]), tb, 0.06)
				tb += beat * 0.5
				step += 1
			for k in 8:
				_flute(buf, _midi([74, 72, 69, 67][k % 4]), 6.0 + k * 5.2, 2.4, 0.06)
		"citadel":
			# Ciudadela: cuerdas graves solemnes, pulso de tambor y señales agudas.
			_pad(buf, [36, 43, 48, 55], 0.0, seconds, 0.06)
			var beat := 60.0 / 76.0
			var tc := 0.0
			var step := 0
			var motif := [60, 63, 67, 63, 65, 62, 60, 58]
			while tc < seconds - 1.0:
				if step % 8 == 0:
					_kick(buf, tc, 0.3)
				if step % 8 == 4:
					_kick(buf, tc, 0.16)
				if step % 16 == 12:
					_snare(buf, tc, 0.12)
				if step % 4 == 0:
					_bass(buf, _midi([36, 36, 41, 39][int(step / 16.0) % 4]), tc, beat * 0.9, 0.12)
				tc += beat * 0.5
				step += 1
			for k in motif.size() * 2:
				_bell(buf, _midi(motif[k % motif.size()] + 12), 4.0 + k * 2.4, 0.045)
			for k in 6:
				_flute(buf, _midi([67, 70, 72, 70, 67, 65][k]), 6.0 + k * 7.0, 3.2, 0.05)
		"archive":
			# Archivo: clavecín pausado en la menor sobre un órgano grave y campanas lejanas.
			_pad(buf, [33, 40, 45], 0.0, seconds, 0.05)
			var prog := [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 56, 59]]
			var bar := 60.0 / 70.0 * 4.0
			var ta := 0.0
			var bi := 0
			while ta < seconds - bar:
				var chord: Array = prog[bi % prog.size()]
				for k in 8:
					var note: int = chord[[0, 1, 2, 1, 0, 2, 1, 2][k]] + (12 if k % 4 == 3 else 0)
					_pluck(buf, _midi(note), ta + k * bar / 8.0, 0.045)
				_bass(buf, _midi(chord[0] - 24), ta, bar * 0.9, 0.07)
				ta += bar
				bi += 1
			for k in 10:
				_bell(buf, _midi([69, 72, 76, 81][rng.randi() % 4]), rng.randf_range(1.0, seconds - 4.0), 0.03)
		"river":
			# Ríos: arpegios que fluyen en mi menor, gotas de campana y bordón suave.
			var chords := [[40, 47, 52, 55], [36, 43, 48, 52], [43, 50, 55, 59], [38, 45, 50, 54]]
			var dur := seconds / chords.size()
			for c in chords.size():
				_pad(buf, chords[c], c * dur, dur + 1.0, 0.045)
			var eighth := 60.0 / 84.0 * 0.5
			var tr := 0.0
			var step := 0
			while tr < seconds - 1.0:
				var chord: Array = chords[int(tr / dur) % chords.size()]
				var note: int = chord[[1, 2, 3, 2][step % 4]] + 12
				_pluck(buf, _midi(note), tr, 0.05)
				if step % 16 == 0:
					_bass(buf, _midi(chord[0]), tr, eighth * 6.0, 0.08)
				tr += eighth
				step += 1
			for k in 30:
				_bell(buf, _midi([76, 79, 83, 86, 88][rng.randi() % 5]), rng.randf_range(0.5, seconds - 3.0), 0.035)
			for k in 6:
				_flute(buf, _midi([71, 69, 67, 64, 66, 67][k]), 4.0 + k * 7.0, 3.0, 0.05)
		_:
			# Bosque: acordes etéreos y campanas.
			var chords := [[50, 57, 62, 65], [46, 53, 58, 62], [41, 48, 53, 57], [48, 55, 60, 64]]
			var dur := seconds / chords.size()
			for c in chords.size():
				_pad(buf, chords[c], c * dur, dur + 1.5, 0.05)
			var bells := [62, 65, 67, 69, 72, 74, 77]
			for k in 26:
				_bell(buf, _midi(bells[rng.randi() % bells.size()]), rng.randf_range(0.5, seconds - 4.0), 0.07)
	# Normalizar suavemente.
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(buf[i]))
	var gain := 0.8 / peak
	for i in n:
		buf[i] = buf[i] * gain
	return buf


func _pad(buf: PackedFloat32Array, notes: Array, start: float, dur: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(dur * RATE)
	for note in notes:
		var f := _midi(note)
		var ph1 := 0.0
		var ph2 := 0.0
		for i in count:
			var idx := (s0 + i) % n
			var t := float(i) / count
			var env := minf(1.0, t * 5.0) * minf(1.0, (1.0 - t) * 5.0)
			ph1 += f / RATE
			ph2 += f * 1.004 / RATE
			var v := sin(TAU * ph1) * 0.6 + sin(TAU * ph2) * 0.4 + sin(TAU * ph1 * 2.0) * 0.12
			buf[idx] += v * env * vol


func _flute(buf: PackedFloat32Array, f: float, start: float, dur: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(dur * RATE)
	var ph := 0.0
	var lp := 0.0
	for i in count:
		var t := float(i) / count
		var vib := sin(TAU * 5.2 * i / RATE) * 0.006 * minf(1.0, t * 3.0)
		ph += f * (1.0 + vib) / RATE
		lp += (randf_range(-1, 1) - lp) * 0.2
		var env := minf(1.0, t * 12.0) * pow(1.0 - t, 1.2)
		var v := sin(TAU * ph) + 0.25 * sin(TAU * ph * 2.0) + lp * 0.12
		buf[(s0 + i) % n] += v * env * vol


func _pluck(buf: PackedFloat32Array, f: float, start: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(2.0 * RATE)
	var ph := 0.0
	for i in count:
		var t := float(i) / count
		ph += f / RATE
		buf[(s0 + i) % n] += (sin(TAU * ph) + 0.4 * sin(TAU * ph * 3.0) * (1.0 - t)) * exp(-t * 6.0) * vol


func _bell(buf: PackedFloat32Array, f: float, start: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(3.5 * RATE)
	for i in count:
		var tt := float(i) / RATE
		var v := sin(TAU * f * tt) + 0.5 * sin(TAU * f * 2.76 * tt) * exp(-tt * 3.0) + 0.3 * sin(TAU * f * 5.4 * tt) * exp(-tt * 6.0)
		buf[(s0 + i) % n] += v * exp(-tt * 1.4) * minf(1.0, i / 40.0) * vol


func _bass(buf: PackedFloat32Array, f: float, start: float, dur: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(dur * RATE)
	var ph := 0.0
	for i in count:
		var t := float(i) / count
		ph += f / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		buf[(s0 + i) % n] += (saw * 0.5 + sin(TAU * ph) * 0.8) * pow(1.0 - t, 1.5) * vol


func _kick(buf: PackedFloat32Array, start: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(0.3 * RATE)
	var ph := 0.0
	for i in count:
		var t := float(i) / count
		ph += lerpf(120.0, 40.0, sqrt(t)) / RATE
		buf[(s0 + i) % n] += sin(TAU * ph) * pow(1.0 - t, 2.0) * vol


func _snare(buf: PackedFloat32Array, start: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(0.2 * RATE)
	for i in count:
		var t := float(i) / count
		buf[(s0 + i) % n] += randf_range(-1, 1) * pow(1.0 - t, 3.0) * vol


func _hat(buf: PackedFloat32Array, start: float, vol: float) -> void:
	var n := buf.size()
	var s0 := int(start * RATE)
	var count := int(0.05 * RATE)
	var prev := 0.0
	for i in count:
		var t := float(i) / count
		var x := randf_range(-1, 1)
		buf[(s0 + i) % n] += (x - prev) * pow(1.0 - t, 2.0) * vol
		prev = x
