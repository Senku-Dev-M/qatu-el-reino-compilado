class_name Themes
extends RefCounted
## Paletas y estilos visuales por región. Colores con componentes > 1
## son HDR y producen brillo (glow).

static func get_theme(name: String) -> Dictionary:
	match name:
		"hub":
			return {
				"style": "hub",
				"sky_top": Color(0.02, 0.03, 0.08), "sky_bottom": Color(0.16, 0.12, 0.16),
				"far": Color(0.09, 0.09, 0.15), "mid": Color(0.06, 0.06, 0.1), "near": Color(0.035, 0.035, 0.06),
				"rock": Color(0.05, 0.045, 0.06), "rock_deep": Color(0.025, 0.02, 0.03),
				"rim": Color(0.55, 0.45, 0.35), "moss": Color(0.3, 0.26, 0.2),
				"glow": Color(2.4, 1.6, 0.6), "accent": Color(2.0, 1.4, 0.55),
				"ambient": Color(0.62, 0.6, 0.72), "spore": Color(1.6, 1.2, 0.6, 0.55),
				"fog": Color(0.5, 0.4, 0.45, 0.07),
			}
		"hub_restored":
			return {
				"style": "hub",
				"sky_top": Color(0.04, 0.06, 0.12), "sky_bottom": Color(0.24, 0.18, 0.28),
				"far": Color(0.14, 0.14, 0.22), "mid": Color(0.1, 0.1, 0.16), "near": Color(0.06, 0.06, 0.1),
				"rock": Color(0.08, 0.07, 0.1), "rock_deep": Color(0.04, 0.035, 0.05),
				"rim": Color(0.9, 0.75, 0.45), "moss": Color(0.5, 0.45, 0.3),
				"glow": Color(2.8, 2.2, 0.9), "accent": Color(2.6, 1.8, 0.8),
				"ambient": Color(0.85, 0.82, 0.92), "spore": Color(2.2, 1.8, 0.9, 0.6),
				"fog": Color(0.6, 0.5, 0.65, 0.06),
			}
		"backend_ruins":
			return {
				"style": "engine",
				"sky_top": Color(0.04, 0.02, 0.06), "sky_bottom": Color(0.16, 0.08, 0.14),
				"far": Color(0.14, 0.08, 0.16), "mid": Color(0.09, 0.05, 0.11), "near": Color(0.05, 0.03, 0.06),
				"rock": Color(0.07, 0.04, 0.08), "rock_deep": Color(0.035, 0.02, 0.04),
				"rim": Color(0.85, 0.45, 0.75), "moss": Color(0.45, 0.25, 0.45),
				"glow": Color(2.6, 0.8, 1.8), "accent": Color(2.4, 0.9, 2.0),
				"ambient": Color(0.72, 0.62, 0.78), "spore": Color(2.2, 0.8, 1.6, 0.5),
				"fog": Color(0.7, 0.35, 0.6, 0.06),
			}
		"database_abyss":
			return {
				"style": "arena",
				"sky_top": Color(0.02, 0.01, 0.05), "sky_bottom": Color(0.1, 0.04, 0.15),
				"far": Color(0.1, 0.04, 0.18), "mid": Color(0.06, 0.025, 0.12), "near": Color(0.03, 0.015, 0.06),
				"rock": Color(0.045, 0.02, 0.08), "rock_deep": Color(0.02, 0.01, 0.04),
				"rim": Color(0.6, 0.3, 0.9), "moss": Color(0.35, 0.15, 0.55),
				"glow": Color(2.4, 0.4, 2.8), "accent": Color(0.6, 1.4, 2.8),
				"ambient": Color(0.58, 0.48, 0.72), "spore": Color(2.0, 0.5, 2.6, 0.5),
				"fog": Color(0.5, 0.2, 0.7, 0.07),
			}
		"towers":
			return {
				"style": "citadel",
				"sky_top": Color(0.03, 0.05, 0.12), "sky_bottom": Color(0.14, 0.18, 0.32),
				"far": Color(0.16, 0.18, 0.34), "mid": Color(0.1, 0.12, 0.24), "near": Color(0.06, 0.07, 0.14),
				"rock": Color(0.07, 0.08, 0.16), "rock_deep": Color(0.035, 0.04, 0.08),
				"rim": Color(0.5, 0.8, 1.2), "moss": Color(0.35, 0.5, 0.7),
				"glow": Color(0.6, 2.2, 2.8), "accent": Color(2.4, 1.8, 0.6),
				"ambient": Color(0.82, 0.86, 0.94), "spore": Color(0.8, 2.0, 2.6, 0.45),
				"fog": Color(0.4, 0.6, 0.85, 0.06),
			}
		"clean_arch":
			return {
				"style": "citadel_vault",
				"sky_top": Color(0.02, 0.04, 0.08), "sky_bottom": Color(0.08, 0.14, 0.24),
				"far": Color(0.1, 0.14, 0.26), "mid": Color(0.06, 0.09, 0.18), "near": Color(0.035, 0.05, 0.1),
				"rock": Color(0.05, 0.07, 0.14), "rock_deep": Color(0.025, 0.035, 0.07),
				"rim": Color(0.4, 0.9, 1.4), "moss": Color(0.3, 0.6, 0.8),
				"glow": Color(0.5, 2.4, 2.8), "accent": Color(2.6, 2.0, 0.8),
				"ambient": Color(0.78, 0.84, 0.92), "spore": Color(0.6, 2.2, 2.6, 0.45),
				"fog": Color(0.35, 0.55, 0.8, 0.06),
			}
		"container_port":
			return {
				"style": "canyon",
				"sky_top": Color(0.04, 0.08, 0.14), "sky_bottom": Color(0.18, 0.32, 0.42),
				"far": Color(0.16, 0.26, 0.36), "mid": Color(0.1, 0.18, 0.25), "near": Color(0.05, 0.09, 0.14),
				"rock": Color(0.06, 0.1, 0.15), "rock_deep": Color(0.03, 0.05, 0.08),
				"rim": Color(0.4, 0.8, 1.1), "moss": Color(0.3, 0.55, 0.65),
				"glow": Color(0.4, 1.8, 2.6), "accent": Color(2.4, 1.5, 0.4),
				"ambient": Color(0.75, 0.85, 0.9), "spore": Color(0.6, 1.8, 2.4, 0.45),
				"fog": Color(0.4, 0.65, 0.8, 0.07),
			}
		"k8s_dock":
			return {
				"style": "engine",
				"sky_top": Color(0.02, 0.06, 0.12), "sky_bottom": Color(0.1, 0.2, 0.35),
				"far": Color(0.12, 0.22, 0.38), "mid": Color(0.08, 0.14, 0.25), "near": Color(0.04, 0.07, 0.14),
				"rock": Color(0.05, 0.08, 0.16), "rock_deep": Color(0.025, 0.04, 0.08),
				"rim": Color(0.3, 0.9, 1.4), "moss": Color(0.2, 0.6, 0.8),
				"glow": Color(0.3, 2.2, 2.8), "accent": Color(2.6, 1.6, 0.4),
				"ambient": Color(0.76, 0.86, 0.95), "spore": Color(0.5, 2.0, 2.8, 0.5),
				"fog": Color(0.3, 0.6, 0.9, 0.07),
			}
		"qa_lab":
			return {
				"style": "archive",
				"sky_top": Color(0.03, 0.05, 0.08), "sky_bottom": Color(0.12, 0.2, 0.24),
				"far": Color(0.14, 0.22, 0.26), "mid": Color(0.09, 0.14, 0.18), "near": Color(0.045, 0.07, 0.09),
				"rock": Color(0.06, 0.09, 0.11), "rock_deep": Color(0.03, 0.045, 0.06),
				"rim": Color(0.4, 1.0, 0.8), "moss": Color(0.25, 0.65, 0.5),
				"glow": Color(0.4, 2.6, 1.8), "accent": Color(2.4, 0.8, 0.5),
				"ambient": Color(0.8, 0.9, 0.86), "spore": Color(0.6, 2.4, 1.6, 0.45),
				"fog": Color(0.35, 0.7, 0.6, 0.06),
			}
		"security_vault":
			return {
				"style": "archive_vault",
				"vault": true,
				"sky_top": Color(0.04, 0.02, 0.04), "sky_bottom": Color(0.18, 0.08, 0.14),
				"far": Color(0.2, 0.1, 0.16), "mid": Color(0.12, 0.06, 0.1), "near": Color(0.06, 0.03, 0.05),
				"rock": Color(0.08, 0.04, 0.07), "rock_deep": Color(0.04, 0.02, 0.035),
				"rim": Color(1.2, 0.4, 0.5), "moss": Color(0.7, 0.3, 0.4),
				"glow": Color(2.8, 0.5, 0.8), "accent": Color(2.4, 1.6, 0.5),
				"ambient": Color(0.85, 0.72, 0.78), "spore": Color(2.4, 0.6, 0.9, 0.45),
				"fog": Color(0.7, 0.3, 0.45, 0.06),
			}
		"cave":
			return {
				"style": "cave",
				"sky_top": Color(0.02, 0.02, 0.06), "sky_bottom": Color(0.05, 0.04, 0.12),
				"far": Color(0.07, 0.06, 0.16), "mid": Color(0.045, 0.04, 0.11), "near": Color(0.03, 0.025, 0.07),
				"rock": Color(0.04, 0.035, 0.08), "rock_deep": Color(0.02, 0.015, 0.04),
				"rim": Color(0.35, 0.4, 0.75), "moss": Color(0.2, 0.25, 0.5),
				"glow": Color(0.6, 1.6, 2.6), "accent": Color(0.7, 1.4, 2.8),
				"ambient": Color(0.55, 0.58, 0.75), "spore": Color(0.8, 1.2, 2.4, 0.5),
				"fog": Color(0.35, 0.4, 0.8, 0.06),
			}
		"engine":
			return {
				"style": "engine",
				"sky_top": Color(0.05, 0.02, 0.01), "sky_bottom": Color(0.14, 0.06, 0.02),
				"far": Color(0.16, 0.08, 0.03), "mid": Color(0.1, 0.05, 0.02), "near": Color(0.05, 0.03, 0.015),
				"rock": Color(0.06, 0.035, 0.02), "rock_deep": Color(0.03, 0.015, 0.01),
				"rim": Color(0.8, 0.5, 0.2), "moss": Color(0.5, 0.3, 0.1),
				"glow": Color(2.8, 1.4, 0.3), "accent": Color(2.6, 1.2, 0.3),
				"ambient": Color(0.7, 0.58, 0.5), "spore": Color(2.2, 1.0, 0.3, 0.6),
				"fog": Color(0.8, 0.4, 0.1, 0.06),
			}
		"canyon":
			return {
				"style": "canyon",
				"sky_top": Color(0.16, 0.06, 0.16), "sky_bottom": Color(0.62, 0.3, 0.16),
				"far": Color(0.34, 0.15, 0.12), "mid": Color(0.2, 0.09, 0.07), "near": Color(0.09, 0.04, 0.035),
				"rock": Color(0.1, 0.05, 0.035), "rock_deep": Color(0.05, 0.025, 0.02),
				"rim": Color(0.95, 0.55, 0.25), "moss": Color(0.55, 0.42, 0.2),
				"glow": Color(0.5, 2.0, 2.1), "accent": Color(2.4, 1.5, 0.45),
				"ambient": Color(0.78, 0.66, 0.62), "spore": Color(2.0, 1.2, 0.6, 0.45),
				"fog": Color(0.9, 0.5, 0.3, 0.07),
			}
		"river":
			return {
				"style": "river",
				"water": true,
				"sky_top": Color(0.03, 0.09, 0.12), "sky_bottom": Color(0.14, 0.3, 0.32),
				"far": Color(0.1, 0.2, 0.23), "mid": Color(0.06, 0.12, 0.14), "near": Color(0.03, 0.06, 0.07),
				"rock": Color(0.05, 0.08, 0.09), "rock_deep": Color(0.025, 0.04, 0.05),
				"rim": Color(0.45, 0.8, 0.75), "moss": Color(0.3, 0.55, 0.4),
				"glow": Color(0.5, 2.0, 2.2), "accent": Color(2.4, 1.7, 0.5),
				"ambient": Color(0.74, 0.84, 0.86), "spore": Color(0.8, 2.0, 2.2, 0.5),
				"fog": Color(0.5, 0.8, 0.85, 0.08),
				"water_deep": Color(0.02, 0.14, 0.18), "water_surface": Color(0.5, 2.0, 2.2),
			}
		"river_deep":
			return {
				"style": "river",
				"water": true,
				"deep": true,
				"sky_top": Color(0.01, 0.02, 0.05), "sky_bottom": Color(0.04, 0.08, 0.14),
				"far": Color(0.07, 0.1, 0.18), "mid": Color(0.045, 0.07, 0.12), "near": Color(0.025, 0.035, 0.06),
				"rock": Color(0.04, 0.05, 0.08), "rock_deep": Color(0.02, 0.025, 0.04),
				"rim": Color(0.35, 0.55, 0.85), "moss": Color(0.25, 0.4, 0.55),
				"glow": Color(2.4, 1.6, 0.5), "accent": Color(0.5, 1.8, 2.4),
				"ambient": Color(0.72, 0.76, 0.86), "spore": Color(2.2, 1.6, 0.6, 0.45),
				"fog": Color(0.35, 0.5, 0.8, 0.07),
				"water_deep": Color(0.02, 0.06, 0.14), "water_surface": Color(0.5, 1.4, 2.6),
			}
		"archive":
			return {
				"style": "archive",
				"sky_top": Color(0.05, 0.03, 0.03), "sky_bottom": Color(0.2, 0.12, 0.07),
				"far": Color(0.22, 0.14, 0.1), "mid": Color(0.14, 0.09, 0.06), "near": Color(0.06, 0.04, 0.03),
				"rock": Color(0.09, 0.06, 0.045), "rock_deep": Color(0.045, 0.03, 0.02),
				"rim": Color(0.85, 0.62, 0.35), "moss": Color(0.7, 0.62, 0.45),
				"glow": Color(2.4, 1.6, 0.6), "accent": Color(2.2, 1.7, 0.9),
				"ambient": Color(0.9, 0.82, 0.74), "spore": Color(1.8, 1.5, 1.0, 0.45),
				"fog": Color(0.7, 0.5, 0.3, 0.06),
			}
		"archive_vault":
			return {
				"style": "archive",
				"vault": true,
				"sky_top": Color(0.02, 0.02, 0.06), "sky_bottom": Color(0.08, 0.06, 0.16),
				"far": Color(0.1, 0.08, 0.18), "mid": Color(0.06, 0.05, 0.12), "near": Color(0.03, 0.025, 0.06),
				"rock": Color(0.06, 0.05, 0.1), "rock_deep": Color(0.03, 0.025, 0.05),
				"rim": Color(0.55, 0.5, 0.95), "moss": Color(0.5, 0.55, 0.8),
				"glow": Color(1.0, 1.6, 2.6), "accent": Color(2.2, 1.7, 0.9),
				"ambient": Color(0.74, 0.74, 0.88), "spore": Color(1.2, 1.6, 2.6, 0.45),
				"fog": Color(0.45, 0.4, 0.8, 0.07),
			}
		"citadel":
			return {
				"style": "citadel",
				"sky_top": Color(0.03, 0.03, 0.1), "sky_bottom": Color(0.12, 0.1, 0.24),
				"far": Color(0.14, 0.12, 0.26), "mid": Color(0.09, 0.08, 0.18), "near": Color(0.05, 0.04, 0.1),
				"rock": Color(0.08, 0.07, 0.14), "rock_deep": Color(0.04, 0.035, 0.07),
				"rim": Color(0.8, 0.65, 0.35), "moss": Color(0.45, 0.4, 0.55),
				"glow": Color(2.4, 1.9, 0.8), "accent": Color(0.6, 1.6, 2.4),
				"ambient": Color(0.82, 0.78, 0.86), "spore": Color(2.2, 1.7, 0.8, 0.45),
				"fog": Color(0.5, 0.45, 0.8, 0.07),
			}
		"citadel_vault":
			return {
				"style": "citadel",
				"idp": true,
				"sky_top": Color(0.02, 0.01, 0.08), "sky_bottom": Color(0.1, 0.05, 0.2),
				"far": Color(0.14, 0.08, 0.24), "mid": Color(0.09, 0.05, 0.16), "near": Color(0.05, 0.03, 0.09),
				"rock": Color(0.07, 0.04, 0.12), "rock_deep": Color(0.035, 0.02, 0.06),
				"rim": Color(0.65, 0.5, 1.0), "moss": Color(0.5, 0.4, 0.75),
				"glow": Color(1.2, 1.4, 2.8), "accent": Color(2.4, 1.6, 0.9),
				"ambient": Color(0.8, 0.76, 0.92), "spore": Color(1.2, 1.6, 2.8, 0.45),
				"fog": Color(0.45, 0.35, 0.9, 0.07),
			}
		"canyon_night":
			return {
				"style": "canyon",
				"night": true,
				"sky_top": Color(0.03, 0.03, 0.09), "sky_bottom": Color(0.22, 0.1, 0.2),
				"far": Color(0.2, 0.12, 0.2), "mid": Color(0.12, 0.07, 0.11), "near": Color(0.055, 0.03, 0.045),
				"rock": Color(0.07, 0.04, 0.04), "rock_deep": Color(0.035, 0.02, 0.02),
				"rim": Color(0.85, 0.45, 0.3), "moss": Color(0.45, 0.3, 0.25),
				"glow": Color(2.4, 1.4, 0.4), "accent": Color(0.5, 2.0, 2.1),
				"ambient": Color(0.82, 0.76, 0.86), "spore": Color(2.2, 1.4, 0.5, 0.5),
				"fog": Color(0.6, 0.35, 0.5, 0.07),
			}
		"arena":
			return {
				"style": "arena",
				"sky_top": Color(0.04, 0.01, 0.06), "sky_bottom": Color(0.13, 0.03, 0.14),
				"far": Color(0.12, 0.04, 0.16), "mid": Color(0.08, 0.025, 0.1), "near": Color(0.04, 0.015, 0.05),
				"rock": Color(0.05, 0.02, 0.06), "rock_deep": Color(0.025, 0.01, 0.03),
				"rim": Color(0.7, 0.3, 0.7), "moss": Color(0.45, 0.15, 0.45),
				"glow": Color(2.6, 0.5, 2.2), "accent": Color(0.5, 2.2, 2.6),
				"ambient": Color(0.62, 0.52, 0.68), "spore": Color(2.2, 0.6, 2.0, 0.5),
				"fog": Color(0.6, 0.2, 0.6, 0.07),
			}
		_:  # forest (Bosque del DOM)
			return {
				"style": "forest",
				"sky_top": Color(0.01, 0.04, 0.05), "sky_bottom": Color(0.04, 0.13, 0.14),
				"far": Color(0.05, 0.14, 0.15), "mid": Color(0.03, 0.09, 0.1), "near": Color(0.02, 0.05, 0.055),
				"rock": Color(0.025, 0.05, 0.05), "rock_deep": Color(0.012, 0.025, 0.028),
				"rim": Color(0.3, 0.6, 0.55), "moss": Color(0.15, 0.4, 0.33),
				"glow": Color(0.5, 2.4, 2.2), "accent": Color(2.2, 1.5, 0.5),
				"ambient": Color(0.58, 0.68, 0.7), "spore": Color(0.6, 2.0, 1.8, 0.55),
				"fog": Color(0.3, 0.7, 0.65, 0.06),
			}
