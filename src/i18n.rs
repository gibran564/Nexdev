#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Lang {
    Es,
    En,
}

impl Lang {
    pub fn as_str(self) -> &'static str {
        match self {
            Lang::Es => "es",
            Lang::En => "en",
        }
    }
}

pub fn parse_lang(raw: &str) -> Lang {
    if raw.trim().to_lowercase().starts_with("es") {
        Lang::Es
    } else {
        Lang::En
    }
}

pub fn parse_lang_arg(raw: &str) -> Option<Lang> {
    match raw.trim().to_lowercase().as_str() {
        "es" => Some(Lang::Es),
        "en" => Some(Lang::En),
        _ => None,
    }
}

pub fn detect_lang() -> Lang {
    let raw = std::env::var("LANG")
        .or_else(|_| std::env::var("LC_ALL"))
        .or_else(|_| std::env::var("LANGUAGE"))
        .unwrap_or_default();

    parse_lang(&raw)
}

pub fn t(lang: Lang, key: &str) -> &str {
    match (lang, key) {
        (Lang::Es, "setup.title") => "configuracion inicial",
        (Lang::En, "setup.title") => "project navigator setup",
        (Lang::Es, "setup.projects") => "Donde estan tus proyectos?",
        (Lang::En, "setup.projects") => "Where are your projects?",
        (Lang::Es, "setup.projects_hint") => {
            "Enter acepta la ruta sugerida. Despues, Enter vacio termina la lista."
        }
        (Lang::En, "setup.projects_hint") => {
            "Enter accepts the suggested path. After that, empty input finishes the list."
        }
        (Lang::Es, "setup.path_prompt") => "Ruta",
        (Lang::En, "setup.path_prompt") => "Path",
        (Lang::Es, "setup.empty_stop") => "vacio para terminar",
        (Lang::En, "setup.empty_stop") => "empty to stop",
        (Lang::Es, "setup.default_home") => "usando home como ruta por defecto.",
        (Lang::En, "setup.default_home") => "using home as default path.",
        (Lang::Es, "setup.path_missing") => "ruta no encontrada, se omite",
        (Lang::En, "setup.path_missing") => "path not found, skipping",
        (Lang::Es, "setup.editor") => "Editor preferido",
        (Lang::En, "setup.editor") => "Preferred editor",
        (Lang::Es, "setup.editor_hint") => "Se usara para abrir el proyecto seleccionado.",
        (Lang::En, "setup.editor_hint") => "Used to open the selected project.",
        (Lang::Es, "setup.detected") => "[detectado]",
        (Lang::En, "setup.detected") => "[detected]",
        (Lang::Es, "setup.none") => "Ninguno",
        (Lang::En, "setup.none") => "None",
        (Lang::Es, "setup.choice") => "Opcion",
        (Lang::En, "setup.choice") => "Choice",
        (Lang::Es, "setup.summary") => "Resumen:",
        (Lang::En, "setup.summary") => "Summary:",
        (Lang::Es, "setup.summary_language") => "idioma",
        (Lang::En, "setup.summary_language") => "language",
        (Lang::Es, "setup.summary_editor") => "editor",
        (Lang::En, "setup.summary_editor") => "editor",
        (Lang::Es, "setup.summary_config") => "config",
        (Lang::En, "setup.summary_config") => "config",
        (Lang::Es, "setup.save") => "Guardar y continuar?",
        (Lang::En, "setup.save") => "Save and continue?",
        (Lang::Es, "setup.not_saved") => "Configuracion no guardada.",
        (Lang::En, "setup.not_saved") => "Config not saved.",
        (Lang::Es, "setup.saved") => "Configuracion guardada. Usa",
        (Lang::En, "setup.saved") => "Config saved. Run",
        (Lang::Es, "setup.more_roots") => "para agregar mas rutas.",
        (Lang::En, "setup.more_roots") => "to add more roots.",

        (Lang::Es, "cmd.already") => "ya esta en la configuracion",
        (Lang::En, "cmd.already") => "is already in the config",
        (Lang::Es, "cmd.added") => "agregada",
        (Lang::En, "cmd.added") => "added",
        (Lang::Es, "cmd.exclude") => "excluir:",
        (Lang::En, "cmd.exclude") => "exclude:",
        (Lang::Es, "cmd.not_configured") => "no esta en la configuracion:",
        (Lang::En, "cmd.not_configured") => "not found in config:",
        (Lang::Es, "cmd.removed") => "eliminada",
        (Lang::En, "cmd.removed") => "removed",
        (Lang::Es, "cmd.editor_set") => "editor actualizado a",
        (Lang::En, "cmd.editor_set") => "editor set to",
        (Lang::Es, "cmd.lang_set") => "idioma actualizado a",
        (Lang::En, "cmd.lang_set") => "language set to",
        (Lang::Es, "cmd.lang_invalid") => "idioma invalido; usa es o en",
        (Lang::En, "cmd.lang_invalid") => "invalid language; use es or en",
        (Lang::Es, "cmd.no_roots") => "No hay raices configuradas. Usa",
        (Lang::En, "cmd.no_roots") => "No search roots configured. Run",
        (Lang::Es, "cmd.add_one") => "para agregar una.",
        (Lang::En, "cmd.add_one") => "to add one.",
        (Lang::Es, "cmd.roots") => "raiz/raices",
        (Lang::En, "cmd.roots") => "root(s)",
        (Lang::Es, "cmd.entries") => "entradas",
        (Lang::En, "cmd.entries") => "entries",

        (Lang::Es, "nav.root_missing") => "raiz no encontrada, se omite:",
        (Lang::En, "nav.root_missing") => "root not found, skipping:",
        (Lang::Es, "nav.projects_label") => " proyectos ",
        (Lang::En, "nav.projects_label") => " projects ",
        (Lang::Es, "nav.search_label") => " buscar ",
        (Lang::En, "nav.search_label") => " search ",
        (Lang::Es, "nav.preview_label") => " preview ",
        (Lang::En, "nav.preview_label") => " preview ",
        (Lang::Es, "nav.no_roots") => "No hay raices configuradas.",
        (Lang::En, "nav.no_roots") => "No search roots configured.",
        (Lang::Es, "nav.setup") => "Usa",
        (Lang::En, "nav.setup") => "Run",
        (Lang::Es, "nav.setup_tail") => "para configurar.",
        (Lang::En, "nav.setup_tail") => "to set up.",
        (Lang::Es, "nav.no_projects") => "No se encontraron proyectos en las raices configuradas.",
        (Lang::En, "nav.no_projects") => "No projects found in configured roots.",
        (Lang::Es, "nav.reconfigure") => "Agrega una raiz con",
        (Lang::En, "nav.reconfigure") => "Add a root with",
        (Lang::Es, "nav.or_run") => "o usa",
        (Lang::En, "nav.or_run") => "or run",
        (Lang::Es, "nav.reconfigure_tail") => "para reconfigurar.",
        (Lang::En, "nav.reconfigure_tail") => "to reconfigure.",
        (Lang::Es, "nav.fzf_missing") => {
            "fzf no esta en PATH. Instalalo desde https://github.com/junegunn/fzf"
        }
        (Lang::En, "nav.fzf_missing") => {
            "fzf not found in PATH. Install it from https://github.com/junegunn/fzf"
        }

        (Lang::Es, "preview.branch") => "rama",
        (Lang::En, "preview.branch") => "branch",
        (Lang::Es, "preview.remote") => "remoto",
        (Lang::En, "preview.remote") => "remote",
        (Lang::Es, "preview.more") => "mas",
        (Lang::En, "preview.more") => "more",

        (Lang::Es, "shell.title") => "integracion de shell",
        (Lang::En, "shell.title") => "shell integration",
        (Lang::Es, "shell.add") => "Agrega UNO de estos fragmentos al archivo rc de tu shell.",
        (Lang::En, "shell.add") => "Add ONE of these snippets to your shell rc file.",
        (Lang::Es, "shell.reload") => {
            "Despues de agregar el fragmento, recarga tu shell o ejecuta source."
        }
        (Lang::En, "shell.reload") => {
            "After adding the snippet, reload your shell or source the rc file."
        }
        (Lang::Es, "shell.config") => "Configuracion:",
        (Lang::En, "shell.config") => "Config:",

        _ => key,
    }
}
