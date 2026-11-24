class_name Enemy
extends Node3D
## G-28: Gegner-Grundlage. Gegner sitzen auf der Oberfläche eines Sterns (Richtung `dir` im Sternkoordinatensystem), damit der Wedel
## sie trifft: Der Wisch-Zielpunkt liegt immer auf einem Stern. Nur der Host simuliert (`sim`), Clients folgen den gesendeten
## Richtungen (`tick_client`). Entfernte Gegner kehren nach RESPAWN Sekunden zurück.

const RESPAWN := 45.0
const SURFACE := 1.12      # Abstand von der Sternmitte in Radien

var id := 0
var kind := "wollmaus"
var star: Star
var dir := Vector3.UP
var target_dir := Vector3.UP
var alive := true
var respawn_left := 0.0


func attach(s: Star, d: Vector3) -> void:
	star = s
	dir = d.normalized()
	target_dir = dir
	s.add_child(self)
	_update_pos()
	add_to_group("enemies")


func _update_pos() -> void:
	if star != null:
		position = dir * star.radius * SURFACE


func set_alive(a: bool) -> void:
	alive = a
	visible = a
	if a:
		if not is_in_group("enemies"):
			add_to_group("enemies")
	elif is_in_group("enemies"):
		remove_from_group("enemies")


## Mit welchem Werkzeug (CleanTool.Kind) lässt er sich wegputzen? Standard: mit jedem.
func can_remove(_tool: int) -> bool:
	return true


## Host: ein Wisch trifft den Gegner (who = Spieler-ID). Gibt true zurück, wenn er dadurch entfernt wurde.
func on_wipe(_world, _who: int, tool: int) -> bool:
	if can_remove(tool):
		remove()
		return true
	return false


## Trefferradius um den Gegnerpunkt (zusätzlich zum Wischradius).
func hit_radius() -> float:
	return 0.8


## Host: weggeputzt, kommt nach RESPAWN zurück.
func remove() -> void:
	set_alive(false)
	respawn_left = RESPAWN


func world_point() -> Vector3:
	return global_position


## Host-Schritt: Wiederkehr, sonst Verhalten der Unterklasse.
func sim(delta: float, world) -> void:
	if not alive:
		respawn_left -= delta
		if respawn_left <= 0.0:
			set_alive(true)
		return
	act(delta, world)
	_update_pos()


func act(_delta: float, _world) -> void:
	pass


## Client-Schritt: der gesendeten Richtung weich folgen.
func tick_client(delta: float) -> void:
	if alive and not dir.is_equal_approx(target_dir):
		dir = dir.slerp(target_dir, clampf(delta * 8.0, 0.0, 1.0)).normalized()
		_update_pos()


## Dreht `dir` um die Achse `axis` um `angle` (bleibt auf der Kugel).
func rotate_dir(axis: Vector3, angle: float) -> void:
	dir = dir.rotated(axis.normalized(), angle).normalized()


## Index des Sterns, auf dem der Gegner sitzt (-1 unbekannt).
func star_index(world) -> int:
	return world.stars.find(star)
