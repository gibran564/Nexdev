use crate::config::{mocha_green, mocha_mauve, mocha_overlay, mocha_sky, mocha_teal};
use crate::i18n::{t, Lang};
use colored::Colorize;

pub fn print_install_guide(lang: Lang) {
    println!();
    println!(
        "  {}  {}",
        mocha_mauve("nexdev").bold(),
        t(lang, "shell.title")
    );
    println!(
        "  {}",
        mocha_overlay("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━").normal()
    );
    println!();
    println!("  {}", t(lang, "shell.add"));
    println!();

    println!(
        "  {}  {}  ~/.bashrc",
        mocha_teal("bash").bold(),
        mocha_overlay("→").normal()
    );
    println!(
        "  {}",
        mocha_overlay("─────────────────────────────────────────").normal()
    );
    print_snippet(BASH_SNIPPET);
    println!();

    println!(
        "  {}   {}  ~/.zshrc",
        mocha_teal("zsh").bold(),
        mocha_overlay("→").normal()
    );
    println!(
        "  {}",
        mocha_overlay("─────────────────────────────────────────").normal()
    );
    print_snippet(ZSH_SNIPPET);
    println!();

    println!(
        "  {}  {}  ~/.config/fish/functions/nexdev.fish",
        mocha_teal("fish").bold(),
        mocha_overlay("→").normal()
    );
    println!(
        "  {}",
        mocha_overlay("─────────────────────────────────────────").normal()
    );
    print_snippet(FISH_SNIPPET);
    println!();

    println!(
        "  {}  {}  $PROFILE",
        mocha_teal("PowerShell").bold(),
        mocha_overlay("→").normal()
    );
    println!(
        "  {}",
        mocha_overlay("─────────────────────────────────────────").normal()
    );
    print_snippet(POWERSHELL_SNIPPET);
    println!();

    println!("  {}  {}", mocha_green("✓").bold(), t(lang, "shell.reload"));
    println!();
    println!(
        "  {}  {}   {}",
        mocha_overlay("·").normal(),
        t(lang, "shell.config"),
        mocha_sky(&crate::config::config_path().to_string_lossy()).normal()
    );
    println!();
}

fn print_snippet(code: &str) {
    for line in code.lines() {
        println!("    {}", mocha_overlay(line).normal());
    }
}

const BASH_SNIPPET: &str = r#"
# nexdev
nexdev() {
  if [ "$#" -gt 0 ]; then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev "$@")
  [ -n "$selected" ] && cd "$selected"
}
"#;

const ZSH_SNIPPET: &str = r#"
# nexdev
nexdev() {
  if (( $# > 0 )); then
    command nexdev "$@"
    return
  fi

  local selected
  selected=$(command nexdev "$@")
  [[ -n "$selected" ]] && cd "$selected"
}
"#;

const FISH_SNIPPET: &str = r#"
# nexdev
function nexdev
  if test (count $argv) -gt 0
    command nexdev $argv
    return
  end

  set selected (command nexdev $argv)
  if test -n "$selected"
    cd $selected
  end
end
"#;

const POWERSHELL_SNIPPET: &str = r#"
# nexdev
function nexdev {
    if ($args.Count -gt 0) {
        & nexdev.exe @args
        return
    }

    $selected = & nexdev.exe @args
    if ($selected) { Set-Location $selected }
}
"#;
