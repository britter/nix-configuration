_: {
  flake.templates = {
    minimalDevShell = {
      path = ../../templates/minimal-dev-shell;
      description = "A flake with a minimal dev shell for all systems";
    };
    rustDevShell = {
      path = ../../templates/rust-dev-shell;
      description = "A Rust crate with a dev shell and rustfmt/clippy pre-commit hooks";
    };
  };

}
