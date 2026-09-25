extends RefCounted
## Controller: beim Öffnen eines Fensters den ersten bedienbaren Knopf
## anwählen — ohne Fokus kann man mit dem Steuerkreuz nichts auswählen.

static func erster(wurzel: Node) -> void:
	var k := _suche(wurzel)
	if k:
		k.grab_focus.call_deferred()

static func _suche(n: Node) -> Control:
	for c in n.get_children():
		if c is Control and not (c as Control).is_visible_in_tree():
			continue
		if c is Control and (c as Control).focus_mode == Control.FOCUS_ALL \
				and not (c is BaseButton and (c as BaseButton).disabled):
			return c
		var t := _suche(c)
		if t:
			return t
	return null
