use anyhow::{bail, Context, Result};
use colored::Colorize;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::config::{lookup_path, mocha_mauve, mocha_overlay, mocha_red, Config};
use crate::detect::{detect, ICON_FOLDER};
use crate::i18n::{t, Lang};

const FZF_THEME: &str = "bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,\
     fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,\
     marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,\
     border:#6c7086,label:#89b4fa";

struct Entry {
    path: PathBuf,
    label: String,
}

fn scan(cfg: &Config) -> Vec<Entry> {
    let mut entries: Vec<Entry> = vec![];
    let global_exc: Vec<&str> = cfg.global_excludes.iter().map(String::as_str).collect();
    let lang = cfg.lang();

    for root in &cfg.roots {
        if !root.path.exists() {
            eprintln!(
                "  {}  {} {}",
                mocha_red("✗").bold(),
                t(lang, "nav.root_missing"),
                root.path.display()
            );
            continue;
        }

        let local_exc: Vec<&str> = root.exclude.iter().map(String::as_str).collect();

        let Ok(rd) = root.path.read_dir() else {
            continue;
        };

        let mut children: Vec<PathBuf> = rd
            .flatten()
            .filter_map(|e| {
                let p = e.path();
                if !p.is_dir() {
                    return None;
                }
                let name = p.file_name()?.to_string_lossy();
                if name.starts_with('.') {
                    return None;
                }
                if global_exc.contains(&name.as_ref()) || local_exc.contains(&name.as_ref()) {
                    return None;
                }
                Some(p)
            })
            .collect();

        children.sort();

        for child in children {
            if let Some(info) = detect(&child) {
                let name = child
                    .file_name()
                    .map(|n| n.to_string_lossy().into_owned())
                    .unwrap_or_default();

                entries.push(Entry {
                    label: info.label(&name),
                    path: child,
                });
            }
        }
    }

    entries
}

fn write_lookup(entries: &[Entry]) -> Result<Vec<String>> {
    let lookup = lookup_path();

    let mut lookup_content = String::new();
    let mut fzf_lines: Vec<String> = vec![];

    for (idx, entry) in entries.iter().enumerate() {
        lookup_content.push_str(&format!("{}|{}\n", idx, entry.path.to_string_lossy()));
        fzf_lines.push(format!("{}\t{}", idx, entry.label));
    }

    std::fs::write(&lookup, lookup_content)
        .with_context(|| format!("escribiendo lookup en {}", lookup.display()))?;

    Ok(fzf_lines)
}

fn preview_cmd() -> Result<String> {
    let bin = std::env::current_exe().context("no se pudo resolver la ruta del binario")?;
    // `{:?}` pone comillas si el binario vive en una ruta con espacios; Windows vibes, pero salva la run.
    Ok(format!("{:?} __preview {{1}}", bin))
}

fn run_fzf(lines: &[String], lang: Lang) -> Result<Option<String>> {
    let fzf_bin = which::which("fzf").context(t(lang, "nav.fzf_missing"))?;

    let preview = preview_cmd()?;
    let folder_icon = ICON_FOLDER.to_string();
    let prompt = format!("{folder_icon} proyecto > ");

    let args = vec![
        "--prompt".to_string(),
        prompt,
        "--pointer".to_string(),
        ">".to_string(),
        "--marker".to_string(),
        "*".to_string(),
        "--height".to_string(),
        "65%".to_string(),
        "--layout".to_string(),
        "reverse".to_string(),
        "--border".to_string(),
        "rounded".to_string(),
        "--border-label".to_string(),
        format!("  {folder_icon}  nexdev  "),
        "--border-label-pos".to_string(),
        "3".to_string(),
        "--list-label".to_string(),
        t(lang, "nav.projects_label").to_string(),
        "--input-label".to_string(),
        t(lang, "nav.search_label").to_string(),
        "--preview-label".to_string(),
        t(lang, "nav.preview_label").to_string(),
        "--color".to_string(),
        FZF_THEME.to_string(),
        "--highlight-line".to_string(),
        "--scrollbar".to_string(),
        "▌▐".to_string(),
        "--scroll-off".to_string(),
        "3".to_string(),
        "--delimiter".to_string(),
        "\t".to_string(),
        "--with-nth".to_string(),
        "2".to_string(),
        "--preview".to_string(),
        preview,
        "--preview-window".to_string(),
        "right:50%:border-left".to_string(),
        "--info".to_string(),
        "inline".to_string(),
        "--no-multi".to_string(),
    ];

    let mut child = Command::new(&fzf_bin)
        .args(&args)
        .env("NEXDEV_LOOKUP", lookup_path())
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .context("no se pudo abrir fzf")?;

    if let Some(mut stdin) = child.stdin.take() {
        for line in lines {
            writeln!(stdin, "{line}")?;
        }
    }

    let output = child.wait_with_output().context("error al ejecutar fzf")?;

    if output.status.success() {
        let raw = String::from_utf8_lossy(&output.stdout).trim().to_string();
        if raw.is_empty() {
            Ok(None)
        } else {
            Ok(Some(raw))
        }
    } else {
        Ok(None)
    }
}

fn spawn_editor(cmd: &str, path: &Path) {
    let cmd = cmd.trim();
    if cmd.is_empty() || cmd == "none" {
        return;
    }

    #[cfg(windows)]
    let mut command = Command::new("cmd");

    #[cfg(not(windows))]
    let mut command = Command::new("sh");

    let editor_cmd = if cmd.split_whitespace().any(|part| part == ".") {
        cmd.to_string()
    } else {
        format!("{cmd} .")
    };

    #[cfg(windows)]
    command.args(["/C", &editor_cmd]);

    #[cfg(not(windows))]
    command.args(["-c", &editor_cmd]);

    let _ = command.current_dir(path).spawn();
}

fn handle_selection(raw: &str, lookup_lines: &[(usize, String)], cfg: &Config) -> Result<()> {
    let idx_str = raw.split('\t').next().unwrap_or("").trim();
    let idx: usize = idx_str
        .parse()
        .with_context(|| format!("no se pudo leer el indice de fzf: {idx_str:?}"))?;

    let path_str = lookup_lines
        .iter()
        .find_map(|(i, p)| if *i == idx { Some(p.clone()) } else { None })
        .with_context(|| format!("indice {idx} no encontrado en lookup"))?;

    let path = PathBuf::from(&path_str);

    if !path.exists() {
        bail!("la ruta seleccionada ya no existe: {}", path.display());
    }

    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_default();

    let branch_display = if path.join(".git").exists() {
        if let Ok(head) = std::fs::read_to_string(path.join(".git").join("HEAD")) {
            let b = head
                .trim()
                .strip_prefix("ref: refs/heads/")
                .unwrap_or(head.trim())
                .to_string();
            format!("  \x1b[38;2;148;226;213m\u{E0A0}  {b}\x1b[0m",)
        } else {
            String::new()
        }
    } else {
        String::new()
    };

    eprintln!(
        "\n  {}\x1b[1m\u{E0B1}  {name}\x1b[0m{branch_display}",
        "\x1b[38;2;203;166;247m",
    );
    eprintln!("  \x1b[38;2;108;112;134m{}\x1b[0m\n", path.display());

    spawn_editor(&cfg.editor, &path);

    // El wrapper solo espera esta linea en stdout; si metemos ruido aqui, el `cd` se va al isekai.
    println!("{}", path.display());

    Ok(())
}

pub fn run(cfg: &Config) -> Result<()> {
    let lang = cfg.lang();
    if cfg.roots.is_empty() {
        eprintln!(
            "\n  {}  {}\n  {} {} {}\n",
            mocha_red("✗").bold(),
            t(lang, "nav.no_roots"),
            t(lang, "nav.setup"),
            mocha_mauve("nexdev init").bold(),
            t(lang, "nav.setup_tail")
        );
        return Ok(());
    }

    let entries = scan(cfg);

    if entries.is_empty() {
        eprintln!(
            "\n  {}  {}\n  \
             {} {} {} {} {}\n",
            mocha_overlay("—").normal(),
            t(lang, "nav.no_projects"),
            t(lang, "nav.reconfigure"),
            mocha_mauve("nexdev add <path>").bold(),
            t(lang, "nav.or_run"),
            mocha_mauve("nexdev init").bold(),
            t(lang, "nav.reconfigure_tail"),
        );
        return Ok(());
    }

    let fzf_lines = write_lookup(&entries)?;

    let lookup: Vec<(usize, String)> = entries
        .iter()
        .enumerate()
        .map(|(i, e)| (i, e.path.to_string_lossy().into_owned()))
        .collect();

    let selection = run_fzf(&fzf_lines, lang)?;

    if let Some(raw) = selection {
        handle_selection(&raw, &lookup, cfg)?;
    }

    Ok(())
}
