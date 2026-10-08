extends Node
## Bus global de señales. Ningún sistema necesita conocer a los demás.

signal bits_changed(total: int)
signal masks_changed(current: int, maximum: int)
signal energy_changed(value: float)
signal tablilla_read(id: String, is_new: bool)
signal sello_resolved(id: String)
signal enemy_defeated(enemy_id: String, kills: int)
signal ability_granted(id: String)
signal charm_granted(id: String)
signal charms_changed
signal weapon_changed(id: String)
signal skin_changed(id: String)
signal flag_changed(key: String, value: Variant)
signal room_entered(room_id: String)
signal player_died
signal notify(text: String)
signal camera_shake(strength: float, duration: float)
signal hitstop(duration: float)
signal boss_defeated(id: String)
signal ui_opened
signal ui_closed
