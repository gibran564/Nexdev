use anyhow::{Context, Result};
use colored::Colorize;
use std::path::Path;
use std::process::Command;

use crate::config::{
    lookup_path, mocha_blue, mocha_green, mocha_mauve, mocha_overlay, mocha_peach, mocha_sky,
    mocha_teal,
};
use crate::i18n::{t, Lang};

pub fn render_by_index(idx: usize, lang: Lang) -> Result<()> {
    let lookup = std::fs::read_to_string(lookup_path())
        .context("lookup no encontrado; ejecutaste nexdev primero?")?;

    let path_str = lookup
        .lines()
        .find_map(|line| {
            let (i, p) = line.split_once('|')?;
            if i.trim().parse::<usize>().ok()? == idx {
                Some(p.to_string())
            } else {
                None
            }
        })
        .with_context(|| format!("indice {idx} no encontrado en lookup"))?;

    let path = Path::new(&path_str);
    render_path(path, lang)
}

fn render_path(path: &Path, lang: Lang) -> Result<()> {
    let name = path
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| path.to_string_lossy().into_owned());

    println!();
    println!(
        "  {}  {}",
        mocha_mauve(&name).bold(),
        mocha_overlay(&path.to_string_lossy()).normal()
    );
    println!();

    if path.join(".git").exists() {
        if let Ok(head) = std::fs::read_to_string(path.join(".git").join("HEAD")) {
            let branch = head
                .trim()
                .strip_prefix("ref: refs/heads/")
                .unwrap_or(head.trim());
            println!(
                "  {}  {}",
                mocha_teal(t(lang, "preview.branch")).normal(),
                mocha_sky(branch).normal()
            );
        }

        if let Ok(cfg) = std::fs::read_to_string(path.join(".git").join("config")) {
            for line in cfg.lines() {
                let trimmed = line.trim();
                if let Some(url) = trimmed.strip_prefix("url = ") {
                    println!(
                        "  {}  {}",
                        mocha_overlay(t(lang, "preview.remote")).normal(),
                        mocha_overlay(url).normal()
                    );
                    break;
                }
            }
        }

        // El estado de git es bonus track: si falla, el preview no se cae y seguimos como si nada.
        if let Ok(status_output) = Command::new("git")
            .args(["-C", &path.to_string_lossy(), "status", "--short"])
            .output()
        {
            let status = String::from_utf8_lossy(&status_output.stdout);
            let lines: Vec<&str> = status.lines().take(6).collect();
            if !lines.is_empty() {
                println!();
                for line in &lines {
                    let colored = if line.starts_with('M') || line.starts_with(' ') {
                        mocha_peach(line).to_string()
                    } else if line.starts_with('?') {
                        mocha_overlay(line).to_string()
                    } else if line.starts_with('A') || line.starts_with('D') {
                        mocha_green(line).to_string()
                    } else {
                        line.to_string()
                    };
                    println!("  {colored}");
                }
            }
        }

        println!();
    }

    let Ok(rd) = path.read_dir() else {
        return Ok(());
    };

    let mut entries: Vec<_> = rd
        .flatten()
        .filter(|e| !e.file_name().to_string_lossy().starts_with('.'))
        .collect();
    entries.sort_by_key(|e| {
        (
            !e.path().is_dir(),
            e.file_name().to_string_lossy().to_lowercase(),
        )
    });

    for entry in entries.iter().take(28) {
        let fname = entry.file_name().to_string_lossy().into_owned();
        let is_dir = entry.path().is_dir();
        let ext = entry
            .path()
            .extension()
            .map(|x| x.to_string_lossy().to_lowercase());

        let display = if is_dir {
            format!("  {}/", mocha_teal(&fname).normal())
        } else {
            let colored = match ext.as_deref() {
                Some("ts" | "tsx" | "js" | "jsx" | "mjs" | "cjs") => mocha_blue(&fname).to_string(),
                Some("py" | "ipynb") => mocha_peach(&fname).to_string(),
                Some("rs") => mocha_peach(&fname).to_string(),
                Some("go") => mocha_sky(&fname).to_string(),
                Some("md" | "txt" | "rst" | "adoc") => mocha_overlay(&fname).to_string(),
                Some("json" | "yaml" | "yml" | "toml" | "env" | "envrc") => {
                    mocha_green(&fname).to_string()
                }
                Some("ps1" | "sh" | "bash" | "zsh" | "fish" | "bat" | "cmd") => {
                    format!("{}", mocha_teal(&fname).normal())
                }
                Some("cs" | "java" | "kt" | "scala") => mocha_blue(&fname).to_string(),
                Some("html" | "css" | "scss" | "sass" | "svelte" | "vue") => {
                    mocha_peach(&fname).to_string()
                }
                _ => mocha_overlay(&fname).to_string(),
            };
            format!("   {colored}")
        };
        println!("{display}");
    }

    if entries.len() > 28 {
        println!(
            "   {}",
            mocha_overlay(&format!(
                "… {} {}",
                entries.len() - 28,
                t(lang, "preview.more")
            ))
            .normal()
        );
    }

    println!();
    Ok(())
}
