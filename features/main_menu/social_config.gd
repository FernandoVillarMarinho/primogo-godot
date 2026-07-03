class_name SocialConfig
extends RefCounted
## Feature main_menu — carrega o social atrás de configuração (AD-08, BR-046). Os botões
## ficam ocultos enquanto a URL correspondente estiver vazia (Share pendente — G-02).

const PATH := "res://config/social.cfg"
const SEC := "social"

var like_url: String = ""
var share_url: String = ""


func _init(path: String = PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		like_url = str(cfg.get_value(SEC, "like_url", ""))
		share_url = str(cfg.get_value(SEC, "share_url", ""))


func has_like() -> bool:
	return not like_url.strip_edges().is_empty()


func has_share() -> bool:
	return not share_url.strip_edges().is_empty()
