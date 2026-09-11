extends RefCounted
## Lizenzhinweise für den Credits-Bildschirm (Plan 6.1).
## Godot und GodotSteam stehen unter MIT — ihr Hinweis muss jeder Weitergabe
## beiliegen. Die in Godot eingebauten Fremdkomponenten (FreeType, Jolt …) und
## deren Lizenztexte liefert die Engine selbst.
## Eigene Assets und ihre Rechte: docs/lizenzen/README.md.
## Ohne class_name, einbinden per preload.

const GODOTSTEAM := """MIT License

Copyright (c) 2015-Current | GP Garcia, Chris Ridenour, and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."""

## Alle Hinweise als ein Text. Groß (Engine-Lizenzen) — erst beim Öffnen der
## Credits erzeugen, nicht beim Start des Menüs.
static func alle_texte() -> String:
	var teile := PackedStringArray()
	teile.append("— Godot Engine —\n" + Engine.get_license_text())
	teile.append("— GodotSteam —\n" + GODOTSTEAM)
	teile.append("— Steamworks —\nSteam and the Steam logo are trademarks of Valve Corporation.")
	for komponente: Dictionary in Engine.get_copyright_info():
		var zeilen := PackedStringArray()
		for teil: Dictionary in komponente.get("parts", []):
			for c: Variant in teil.get("copyright", []):
				zeilen.append("© " + str(c))
			zeilen.append("License: " + str(teil.get("license", "")))
		teile.append("%s\n%s" % [str(komponente.get("name", "")), "\n".join(zeilen)])
	var lizenzen: Dictionary = Engine.get_license_info()
	for name: String in lizenzen:
		teile.append("— %s —\n%s" % [name, str(lizenzen[name])])
	return "\n\n".join(teile)
