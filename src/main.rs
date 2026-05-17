mod cli;
mod config;
mod detect;
mod i18n;
mod navigator;
mod preview;
mod shell;

use anyhow::Result;
use clap::Parser;
use cli::{Cli, Command};

fn main() -> Result<()> {
    #[cfg(windows)]
    let _ = colored::control::set_virtual_terminal(true);

    let cli = Cli::parse();

    match cli.command {
        None => {
            let cfg = if config::is_first_run() {
                config::run_wizard()?
            } else {
                config::load()?
            };
            navigator::run(&cfg)?;
        }

        Some(Command::Add { path, exclude }) => {
            let mut cfg = config::load()?;
            config::cmd_add(&mut cfg, path, exclude)?;
        }

        Some(Command::Remove { path }) => {
            let mut cfg = config::load()?;
            config::cmd_remove(&mut cfg, &path)?;
        }

        Some(Command::Language { lang }) => {
            let mut cfg = config::load()?;
            config::cmd_set_language(&mut cfg, &lang)?;
        }

        Some(Command::Editor { cmd }) => {
            let mut cfg = config::load()?;
            config::cmd_set_editor(&mut cfg, &cmd)?;
        }

        Some(Command::Paths) => {
            let cfg = config::load()?;
            config::cmd_paths(&cfg);
        }

        Some(Command::Config) => {
            let cfg = config::load()?;
            config::cmd_show_config(&cfg);
        }

        Some(Command::Init) => {
            config::run_wizard()?;
        }

        Some(Command::Install) => {
            let cfg = config::load()?;
            shell::print_install_guide(cfg.lang());
        }

        Some(Command::Preview { idx }) => {
            let cfg = config::load()?;
            preview::render_by_index(idx, cfg.lang())?;
        }
    }

    Ok(())
}
