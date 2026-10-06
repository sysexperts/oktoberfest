extends PanelContainer
## Eine Karte der Vorhersage in der Wetter-App (scenes/ui/wetter_tag.tscn): Tag, Symbol, Temperatur, Ereignis.

func setze(tag: String, art: String, temp: String, ereignis: String) -> void:
	%Tag.text = tag
	%Symbol.setze(art)
	%Temp.text = temp
	%Ereignis.text = ereignis
