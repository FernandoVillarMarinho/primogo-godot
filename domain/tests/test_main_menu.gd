extends GutTest
## Tarefa 13 — features/main_menu: social atrás de config (AD-08/BR-046) e compilação
## das cenas (splash/menu/opções/créditos) com os autoloads resolvidos.

const TMP := "user://test_social.cfg"


func after_each() -> void:
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(TMP)


# ---------------------------------------------------------------- social config (AD-08)

func test_empty_urls_hide_buttons() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("social", "like_url", "")
	cfg.set_value("social", "share_url", "")
	cfg.save(TMP)
	var sc := SocialConfig.new(TMP)
	assert_false(sc.has_like(), "like vazio → botão oculto")
	assert_false(sc.has_share(), "share vazio → botão oculto (G-02 pendente)")


func test_present_url_shows_button() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("social", "like_url", "https://facebook.com/primogo")
	cfg.set_value("social", "share_url", "")
	cfg.save(TMP)
	var sc := SocialConfig.new(TMP)
	assert_true(sc.has_like(), "like preenchido → botão visível")
	assert_eq(sc.like_url, "https://facebook.com/primogo")
	assert_false(sc.has_share(), "share continua oculto")


func test_shipped_social_cfg_has_empty_urls() -> void:
	var sc := SocialConfig.new()   # res://config/social.cfg do repo
	assert_false(sc.has_share(), "o social.cfg versionado nasce com share vazio (URL pendente)")


# ---------------------------------------------------------------- cenas compilam

func test_menu_scenes_compile() -> void:
	assert_not_null(load("res://features/main_menu/splash.gd"), "splash.gd compila")
	assert_not_null(load("res://features/main_menu/main_menu.gd"), "main_menu.gd compila")
	assert_not_null(load("res://features/main_menu/options_overlay.gd"), "options_overlay.gd compila")
	assert_not_null(load("res://features/main_menu/credits.gd"), "credits.gd compila")
