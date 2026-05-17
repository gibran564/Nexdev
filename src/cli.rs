use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(
    name        = "nexdev",
    version,
    author,
    about = "Navegador de proyectos con fzf",
    long_about  = None,
    propagate_version = true,
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Option<Command>,
}

#[derive(Subcommand, Debug)]
pub enum Command {
    /// Agrega una raiz de busqueda.
    Add {
        path: PathBuf,

        #[arg(short, long, num_args = 1.., value_name = "DIR")]
        exclude: Vec<String>,
    },

    /// Elimina una raiz configurada.
    Remove { path: PathBuf },

    /// Cambia el idioma: es o en.
    Language { lang: String },

    /// Lista las raices configuradas.
    Paths,

    /// Cambia el editor.
    Editor { cmd: String },

    /// Muestra la configuracion completa.
    Config,

    /// Ejecuta otra vez el asistente inicial.
    Init,

    /// Imprime la integracion de shell.
    Install,

    /// Comando interno para renderizar el preview de fzf.
    #[command(hide = true, name = "__preview")]
    Preview { idx: usize },
}
