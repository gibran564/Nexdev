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
    /// Guarda una carpeta donde nexdev va a buscar proyectos; como decirle "mira aqui, sensei".
    Add {
        path: PathBuf,

        #[arg(short, long, num_args = 1.., value_name = "DIR")]
        exclude: Vec<String>,
    },

    /// Saca una carpeta de la lista cuando ya no queremos que aparezca en el radar.
    Remove { path: PathBuf },

    /// Cambia el idioma entre `es` y `en`, porque a veces el cerebro bootea distinto.
    Language { lang: String },

    /// Enseña las carpetas guardadas para revisar rapido si metimos bien las rutas.
    Paths,

    /// Cambia el comando del editor que se abre al elegir proyecto.
    Editor { cmd: String },

    /// Imprime la configuracion completa para hacer debugging sin invocar magia negra.
    Config,

    /// Vuelve a correr el asistente inicial por si nos arrepentimos de la primera build.
    Init,

    /// Muestra el wrapper de shell que permite hacer `cd` despues de escoger proyecto.
    Install,

    /// Atajo interno de fzf: pinta el preview; no es para usarlo a mano salvo modo curioso.
    #[command(hide = true, name = "__preview")]
    Preview { idx: usize },
}
