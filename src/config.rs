use anyhow::{bail, Context, Result};
use colored::Colorize;
use serde::{Deserialize, Serialize};
use std::io::{self, Write};
use std::path::{Path, PathBuf};

use crate::i18n::{detect_lang, parse_lang, parse_lang_arg, t, Lang};

pub fn mocha_mauve(s: &str) -> colored::ColoredString {
    s.truecolor(203, 166, 247)
}
pub fn mocha_teal(s: &str) -> colored::ColoredString {
    s.truecolor(148, 226, 213)
}
pub fn mocha_overlay(s: &str) -> colored::ColoredString {
    s.truecolor(108, 112, 134)
}
pub fn mocha_green(s: &str) -> colored::ColoredString {
    s.truecolor(166, 227, 161)
}
pub fn mocha_red(s: &str) -> colored::ColoredString {
    s.truecolor(243, 139, 168)
}
pub fn mocha_peach(s: &str) -> colored::ColoredString {
    s.truecolor(250, 179, 135)
}
pub fn mocha_blue(s: &str) -> colored::ColoredString {
    s.truecolor(137, 180, 250)
}
pub fn mocha_sky(s: &str) -> colored::ColoredString {
    s.truecolor(137, 220, 235)
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchRoot {
    pub path: PathBuf,
    #[serde(default = "default_local_excludes")]
    pub exclude: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default = "default_language")]
    pub language: String,
    #[serde(default = "default_editor")]
    pub editor: String,
    #[serde(default = "default_global_excludes")]
    pub global_excludes: Vec<String>,
    #[serde(default)]
    pub roots: Vec<SearchRoot>,
}

fn default_editor() -> String {
    "code".to_string()
}
fn default_language() -> String {
    detect_lang().as_str().to_string()
}

pub fn default_global_excludes() -> Vec<String> {
    [
        "Desktop",
        "Documents",
        "Downloads",
        "Pictures",
        "Music",
        "Videos",
        "Contacts",
        "Favorites",
        "Links",
        "Saved Games",
        "Searches",
        "OneDrive",
        "AppData",
        "3D Objects",
        "MicrosoftEdgeBackups",
        "scoop",
        "node_modules",
        ".cargo",
        ".rustup",
        "Library",
        "Applications",
        ".git",
        ".venv",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect()
}

fn default_local_excludes() -> Vec<String> {
    vec![]
}

impl Default for Config {
    fn default() -> Self {
        Config {
            language: default_language(),
            editor: default_editor(),
            global_excludes: default_global_excludes(),
            roots: vec![],
        }
    }
}

impl Config {
    pub fn lang(&self) -> Lang {
        parse_lang(&self.language)
    }
}

pub fn config_path() -> PathBuf {
    dirs::config_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("nexdev")
        .join("config.toml")
}

/// Mantiene separado el lookup de cada proceso para evitar cruces entre ejecuciones.
pub fn lookup_path() -> PathBuf {
    if let Ok(path) = std::env::var("NEXDEV_LOOKUP") {
        return PathBuf::from(path);
    }
    std::env::temp_dir().join(format!("nexdev_lookup_{}.txt", std::process::id()))
}

pub fn load() -> Result<Config> {
    let path = config_path();
    if !path.exists() {
        return Ok(Config::default());
    }
    let raw =
        std::fs::read_to_string(&path).with_context(|| format!("leyendo {}", path.display()))?;
    toml::from_str(&raw).with_context(|| format!("parseando {}", path.display()))
}

pub fn save(cfg: &Config) -> Result<()> {
    let path = config_path();
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creando directorio {}", parent.display()))?;
    }
    let toml_str = toml::to_string_pretty(cfg).context("serializando config a TOML")?;
    std::fs::write(&path, toml_str).with_context(|| format!("escribiendo {}", path.display()))
}

pub fn is_first_run() -> bool {
    !config_path().exists()
}

fn prompt_line(msg: &str, default: Option<&str>) -> Result<String> {
    if let Some(d) = default {
        eprint!(
            "  {} {msg} {} ",
            mocha_mauve("?").bold(),
            mocha_overlay(&format!("[{d}]")).normal()
        );
    } else {
        eprint!("  {} {msg} ", mocha_mauve("?").bold());
    }
    io::stderr().flush()?;
    let mut buf = String::new();
    io::stdin().read_line(&mut buf)?;
    let t = buf.trim().to_string();
    if t.is_empty() {
        return Ok(default.unwrap_or("").to_string());
    }
    Ok(t)
}

fn prompt_yn(msg: &str, default_yes: bool) -> Result<bool> {
    let hint = if default_yes { "Y/n" } else { "y/N" };
    eprint!(
        "  {} {msg} {} ",
        mocha_mauve("?").bold(),
        mocha_overlay(&format!("[{hint}]")).normal()
    );
    io::stderr().flush()?;
    let mut buf = String::new();
    io::stdin().read_line(&mut buf)?;
    Ok(match buf.trim().to_lowercase().as_str() {
        "y" | "yes" | "s" | "si" | "sí" => true,
        "n" | "no" => false,
        _ => default_yes,
    })
}

fn expand_tilde(s: &str) -> PathBuf {
    if s.starts_with('~') {
        if let Some(home) = dirs::home_dir() {
            return home.join(s.trim_start_matches("~/").trim_start_matches("~\\"));
        }
    }
    PathBuf::from(s)
}

fn print_step(lang: Lang, current: u8, total: u8, title_key: &str, hint_key: Option<&str>) {
    eprintln!();
    eprintln!(
        "  {}  {}",
        mocha_teal(&format!("{current}/{total}")).bold(),
        t(lang, title_key)
    );
    if let Some(key) = hint_key {
        eprintln!("     {}", mocha_overlay(t(lang, key)).normal());
    }
    eprintln!();
}

fn choose_language() -> Result<Lang> {
    let detected = detect_lang();
    let default_choice = match detected {
        Lang::Es => "1",
        Lang::En => "2",
    };

    eprintln!();
    eprintln!(
        "  {}  {}",
        mocha_mauve("nexdev").bold(),
        mocha_overlay("initial setup / configuracion inicial").normal()
    );
    eprintln!(
        "  {}",
        mocha_overlay("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━").normal()
    );
    eprintln!();
    eprintln!("  {}  Language / Idioma", mocha_teal("1/3").bold());
    eprintln!();
    eprintln!(
        "     {}  {}",
        mocha_mauve("1").bold(),
        mocha_teal("Español").normal()
    );
    eprintln!(
        "     {}  {}",
        mocha_mauve("2").bold(),
        mocha_teal("English").normal()
    );
    eprintln!();

    let input = prompt_line("Selecciona idioma / Choose language", Some(default_choice))?;
    Ok(match input.as_str() {
        "1" | "es" | "ES" | "Español" | "español" => Lang::Es,
        "2" | "en" | "EN" | "English" | "english" => Lang::En,
        _ => detected,
    })
}

pub fn run_wizard() -> Result<Config> {
    let lang = choose_language()?;
    eprintln!();
    eprintln!(
        "  {}  {}",
        mocha_mauve("nexdev").bold(),
        mocha_overlay(t(lang, "setup.title")).normal()
    );
    eprintln!(
        "  {}",
        mocha_overlay("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━").normal()
    );

    print_step(lang, 2, 3, "setup.projects", Some("setup.projects_hint"));

    let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
    let home_str = home.to_string_lossy().to_string();
    let mut roots: Vec<SearchRoot> = vec![];
    let mut root_idx = 1u32;

    loop {
        let default = if root_idx == 1 {
            Some(home_str.as_str())
        } else {
            None
        };
        let input = prompt_line(
            &format!(
                "{} {root_idx} - {}",
                t(lang, "setup.path_prompt"),
                t(lang, "setup.empty_stop")
            ),
            default,
        )?;

        if input.is_empty() {
            if roots.is_empty() {
                eprintln!(
                    "  {}  {}",
                    mocha_peach("!").bold(),
                    t(lang, "setup.default_home")
                );
                roots.push(SearchRoot {
                    path: home.clone(),
                    exclude: vec![],
                });
            }
            break;
        }

        let p = expand_tilde(&input);
        if p.exists() {
            eprintln!(
                "  {}  {}",
                mocha_green("✓").bold(),
                mocha_teal(&p.to_string_lossy()).normal()
            );
            roots.push(SearchRoot {
                path: p,
                exclude: vec![],
            });
            root_idx += 1;
        } else {
            eprintln!(
                "  {}  {}",
                mocha_red("✗").bold(),
                t(lang, "setup.path_missing")
            );
        }
    }

    print_step(lang, 3, 3, "setup.editor", Some("setup.editor_hint"));

    let candidates: &[(&str, &str)] = &[
        ("VS Code", "code"),
        ("Neovim", "nvim"),
        ("Vim", "vim"),
        ("Helix", "hx"),
        ("IntelliJ", "idea"),
        ("Zed", "zed"),
        (t(lang, "setup.none"), "none"),
    ];

    let detected_idx = candidates
        .iter()
        .position(|(_, cmd)| *cmd != "none" && which::which(cmd).is_ok())
        .unwrap_or(0);

    for (i, (name, cmd)) in candidates.iter().enumerate() {
        let marker = if i == detected_idx {
            mocha_teal(">").bold().to_string()
        } else {
            " ".to_string()
        };
        let tag = if *cmd != "none" && which::which(cmd).is_ok() {
            format!("  {}", mocha_green(t(lang, "setup.detected")).normal())
        } else {
            String::new()
        };
        eprintln!("  {}  {}. {}{}", marker, i + 1, name, tag);
    }
    eprintln!();

    let default_editor_choice = (detected_idx + 1).to_string();
    let sel_str = prompt_line(
        &format!("{} (1-{})", t(lang, "setup.choice"), candidates.len()),
        Some(&default_editor_choice),
    )?;
    let sel = sel_str
        .parse::<usize>()
        .unwrap_or(1)
        .saturating_sub(1)
        .min(candidates.len() - 1);
    let editor = if candidates[sel].1 == "none" {
        String::new()
    } else {
        candidates[sel].1.to_string()
    };

    eprintln!();

    let cfg = Config {
        language: lang.as_str().to_string(),
        editor: editor.clone(),
        global_excludes: default_global_excludes(),
        roots,
    };

    eprintln!("  {}", mocha_overlay(t(lang, "setup.summary")).normal());
    eprintln!(
        "    {} {}",
        mocha_mauve(t(lang, "setup.summary_language")).bold(),
        mocha_sky(cfg.language.as_str()).normal()
    );
    for root in &cfg.roots {
        eprintln!(
            "    {} {}",
            mocha_mauve("●").bold(),
            mocha_teal(&root.path.to_string_lossy()).normal()
        );
    }
    eprintln!(
        "    {} {}",
        mocha_mauve(t(lang, "setup.summary_editor")).bold(),
        if cfg.editor.is_empty() {
            mocha_overlay("none").normal()
        } else {
            mocha_sky(&cfg.editor).normal()
        }
    );
    eprintln!(
        "    {} {}",
        mocha_mauve(t(lang, "setup.summary_config")).bold(),
        mocha_overlay(&config_path().to_string_lossy()).normal()
    );
    eprintln!();

    if !prompt_yn(t(lang, "setup.save"), true)? {
        eprintln!(
            "  {} {}",
            mocha_overlay("—").normal(),
            t(lang, "setup.not_saved")
        );
        return Ok(Config::default());
    }

    save(&cfg)?;
    eprintln!(
        "\n  {}  {} {} {}\n",
        mocha_green("✓").bold(),
        t(lang, "setup.saved"),
        mocha_mauve("nexdev add <path>").bold(),
        t(lang, "setup.more_roots")
    );
    Ok(cfg)
}

pub fn cmd_add(cfg: &mut Config, path: PathBuf, exclude: Vec<String>) -> Result<()> {
    let canon = path
        .canonicalize()
        .with_context(|| format!("ruta no encontrada: {}", path.display()))?;

    if cfg.roots.iter().any(|r| r.path == canon) {
        let lang = cfg.lang();
        eprintln!(
            "  {}  {} {}",
            mocha_peach("!").bold(),
            mocha_teal(&canon.to_string_lossy()).normal(),
            t(lang, "cmd.already")
        );
        return Ok(());
    }

    cfg.roots.push(SearchRoot {
        path: canon.clone(),
        exclude: exclude.clone(),
    });
    save(cfg)?;

    let lang = cfg.lang();
    eprintln!(
        "  {}  {} {}{}",
        mocha_green("✓").bold(),
        t(lang, "cmd.added"),
        mocha_teal(&canon.to_string_lossy()).normal(),
        if exclude.is_empty() {
            String::new()
        } else {
            format!(
                "  {} {}",
                mocha_overlay(t(lang, "cmd.exclude")).normal(),
                mocha_peach(&exclude.join(", ")).normal()
            )
        }
    );
    Ok(())
}

pub fn cmd_remove(cfg: &mut Config, path: &Path) -> Result<()> {
    let lang = cfg.lang();
    let before = cfg.roots.len();
    cfg.roots
        .retain(|r| r.path != path && r.path.to_string_lossy() != path.to_string_lossy());
    if cfg.roots.len() == before {
        eprintln!(
            "  {}  {} {}",
            mocha_peach("!").bold(),
            t(lang, "cmd.not_configured"),
            mocha_overlay(&path.to_string_lossy()).normal()
        );
    } else {
        save(cfg)?;
        eprintln!(
            "  {}  {} {}",
            mocha_green("✓").bold(),
            t(lang, "cmd.removed"),
            mocha_teal(&path.to_string_lossy()).normal()
        );
    }
    Ok(())
}

pub fn cmd_set_editor(cfg: &mut Config, cmd: &str) -> Result<()> {
    cfg.editor = if cmd == "none" {
        String::new()
    } else {
        cmd.to_string()
    };
    save(cfg)?;
    let lang = cfg.lang();
    eprintln!(
        "  {}  {} {}",
        mocha_green("✓").bold(),
        t(lang, "cmd.editor_set"),
        if cfg.editor.is_empty() {
            mocha_overlay("none").normal()
        } else {
            mocha_sky(&cfg.editor).normal()
        }
    );
    Ok(())
}

pub fn cmd_set_language(cfg: &mut Config, lang: &str) -> Result<()> {
    let Some(next_lang) = parse_lang_arg(lang) else {
        bail!("{}", t(cfg.lang(), "cmd.lang_invalid"));
    };
    cfg.language = next_lang.as_str().to_string();
    save(cfg)?;
    eprintln!(
        "  {}  {} {}",
        mocha_green("✓").bold(),
        t(cfg.lang(), "cmd.lang_set"),
        mocha_sky(&cfg.language).normal()
    );
    Ok(())
}

pub fn cmd_paths(cfg: &Config) {
    let lang = cfg.lang();
    if cfg.roots.is_empty() {
        eprintln!(
            "\n  {}  {} {} {}\n",
            mocha_overlay("—").normal(),
            t(lang, "cmd.no_roots"),
            mocha_mauve("nexdev add <path>").bold(),
            t(lang, "cmd.add_one")
        );
        return;
    }
    eprintln!();
    eprintln!(
        "  {}  {} {}\n",
        mocha_mauve("nexdev").bold(),
        cfg.roots.len(),
        t(lang, "cmd.roots")
    );
    for root in &cfg.roots {
        let exists = if root.path.exists() {
            mocha_green("✓").bold().to_string()
        } else {
            mocha_red("✗").bold().to_string()
        };
        eprintln!(
            "  {}  {}{}",
            exists,
            mocha_teal(&root.path.to_string_lossy()).normal(),
            if root.exclude.is_empty() {
                String::new()
            } else {
                format!(
                    "  {} {}",
                    mocha_overlay(t(lang, "cmd.exclude")),
                    mocha_peach(&root.exclude.join(", "))
                )
            }
        );
    }
    eprintln!();
}

pub fn cmd_show_config(cfg: &Config) {
    let lang = cfg.lang();
    eprintln!();
    eprintln!(
        "  {}  {}",
        mocha_mauve("config").bold(),
        mocha_overlay(&config_path().to_string_lossy()).normal()
    );
    eprintln!();
    eprintln!(
        "  {} {}",
        mocha_overlay("editor").normal(),
        if cfg.editor.is_empty() {
            mocha_overlay("none").normal()
        } else {
            mocha_sky(&cfg.editor).normal()
        }
    );
    eprintln!(
        "  {} {}",
        mocha_overlay("language").normal(),
        mocha_sky(&cfg.language).normal()
    );
    eprintln!();
    for root in &cfg.roots {
        eprintln!(
            "  {} {}",
            mocha_mauve("root").bold(),
            mocha_teal(&root.path.to_string_lossy()).normal()
        );
        if !root.exclude.is_empty() {
            eprintln!(
                "       {} {}",
                mocha_overlay(t(lang, "cmd.exclude")).normal(),
                mocha_peach(&root.exclude.join(", ")).normal()
            );
        }
    }
    eprintln!();
    eprintln!(
        "  {} {}",
        mocha_overlay("global_excludes").normal(),
        mocha_overlay(&format!(
            "({} {})",
            cfg.global_excludes.len(),
            t(lang, "cmd.entries")
        ))
        .normal()
    );
    eprintln!();
}
