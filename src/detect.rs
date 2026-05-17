use std::path::Path;

pub const ICON_GIT: char = '\u{E0A0}';
pub const ICON_GITHUB: char = '\u{E709}';
pub const ICON_GITLAB: char = '\u{F296}';
pub const ICON_AZURE: char = '\u{EBE8}';
pub const ICON_NODE: char = '\u{E718}';
pub const ICON_REACT: char = '\u{E7BA}';
pub const ICON_NEXT: char = '\u{E711}';
pub const ICON_VUE: char = '\u{FD42}';
pub const ICON_PYTHON: char = '\u{E73C}';
pub const ICON_RUST: char = '\u{E7A8}';
pub const ICON_DOTNET: char = '\u{E77F}';
pub const ICON_JAVA: char = '\u{E738}';
pub const ICON_GO: char = '\u{E724}';
pub const ICON_FOLDER: char = '\u{F07B}';

pub struct ProjectInfo {
    pub icon: char,
    pub tags: Vec<&'static str>,
}

impl ProjectInfo {
    pub fn label(&self, name: &str) -> String {
        if self.tags.is_empty() {
            format!("{}  {}", self.icon, name)
        } else {
            format!("{}  {}  · {}", self.icon, name, self.tags.join(" · "))
        }
    }
}

pub fn detect(dir: &Path) -> Option<ProjectInfo> {
    let mut tags: Vec<&'static str> = vec![];
    let mut icon: Option<char> = None;
    let mut remote = String::new();

    if dir.join(".git").exists() {
        tags.push("git");

        let git_config = dir.join(".git").join("config");
        if let Ok(content) = std::fs::read_to_string(&git_config) {
            for line in content.lines() {
                let trimmed = line.trim();
                if trimmed.starts_with("url = ") {
                    remote = trimmed["url = ".len()..].to_string();
                    break;
                }
            }
        }

        let git_icon = if remote.contains("github") {
            ICON_GITHUB
        } else if remote.contains("gitlab") {
            ICON_GITLAB
        } else if remote.contains("azure") || remote.contains("visualstudio") {
            ICON_AZURE
        } else {
            ICON_GIT
        };
        icon = Some(git_icon);
    }

    if dir.join("package.json").exists() {
        let raw = std::fs::read_to_string(dir.join("package.json")).unwrap_or_default();

        let has_next = raw.contains("\"next\"")
            || dir.join("next.config.js").exists()
            || dir.join("next.config.mjs").exists()
            || dir.join("next.config.ts").exists();

        let has_react = raw.contains("\"react\"")
            || dir.join("src").join("App.tsx").exists()
            || dir.join("src").join("App.jsx").exists();

        let has_vue = raw.contains("\"vue\"") || dir.join("src").join("App.vue").exists();

        let has_svelte = raw.contains("\"svelte\"");
        let has_tailwind = dir.join("tailwind.config.js").exists()
            || dir.join("tailwind.config.ts").exists()
            || dir.join("tailwind.config.mjs").exists();

        if has_next {
            tags.push("next");
            if icon.is_none() {
                icon = Some(ICON_NEXT);
            }
        } else if has_react {
            tags.push("react");
            if icon.is_none() {
                icon = Some(ICON_REACT);
            }
        } else if has_vue {
            tags.push("vue");
            if icon.is_none() {
                icon = Some(ICON_VUE);
            }
        } else if has_svelte {
            tags.push("svelte");
            if icon.is_none() {
                icon = Some(ICON_NODE);
            }
        } else {
            tags.push("node");
            if icon.is_none() {
                icon = Some(ICON_NODE);
            }
        }

        if has_tailwind {
            tags.push("tailwind");
        }
    }

    let is_python = dir.join("requirements.txt").exists()
        || dir.join("pyproject.toml").exists()
        || dir.join("setup.py").exists()
        || dir.join("setup.cfg").exists()
        || dir.join("Pipfile").exists();

    if is_python {
        let is_notebook = dir
            .read_dir()
            .ok()
            .map(|rd| {
                rd.flatten()
                    .any(|e| e.path().extension().map_or(false, |x| x == "ipynb"))
            })
            .unwrap_or(false);

        if is_notebook {
            tags.push("jupyter");
        } else {
            tags.push("python");
        }
        if icon.is_none() {
            icon = Some(ICON_PYTHON);
        }
    }

    if dir.join("Cargo.toml").exists() {
        tags.push("rust");
        if icon.is_none() {
            icon = Some(ICON_RUST);
        }
    }

    let is_dotnet = dir
        .read_dir()
        .ok()
        .map(|rd| {
            rd.flatten().any(|e| {
                let ext = e
                    .path()
                    .extension()
                    .map(|x| x.to_string_lossy().into_owned());
                matches!(
                    ext.as_deref(),
                    Some("sln") | Some("csproj") | Some("fsproj")
                )
            })
        })
        .unwrap_or(false);
    if is_dotnet {
        tags.push("dotnet");
        if icon.is_none() {
            icon = Some(ICON_DOTNET);
        }
    }

    if dir.join("pom.xml").exists()
        || dir.join("build.gradle").exists()
        || dir.join("build.gradle.kts").exists()
    {
        tags.push("java");
        if icon.is_none() {
            icon = Some(ICON_JAVA);
        }
    }

    if dir.join("go.mod").exists() {
        tags.push("go");
        if icon.is_none() {
            icon = Some(ICON_GO);
        }
    }

    if tags.is_empty() {
        return None;
    }

    Some(ProjectInfo {
        icon: icon.unwrap_or(ICON_FOLDER),
        tags,
    })
}
