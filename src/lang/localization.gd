extends Node

var language_specific_map:Dictionary = {
	"zh_CN": load("res://src/lang/language_specific_zh_cn.gd"),
	"en": load("res://src/lang/language_specific_en.gd")
}

func move_name_to_pronounce(move_name:String) -> String:
	return language_specific_map[TranslationServer.get_locale()].move_name_to_pronounce(move_name)

func position_name_to_pronounce(position_name:String) -> String:
	return language_specific_map[TranslationServer.get_locale()].position_name_to_pronounce(position_name)
