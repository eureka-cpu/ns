use std::env;
use std::process::Command;

#[test]
fn flake_current_dir() {
    let project_root = env::current_dir().expect("failed to get test directory");
    let bin = project_root
        .join("../bin/main.exe")
        .canonicalize()
        .expect("failed to canonicalize path");
    let ns = Command::new(bin)
        .args([".", "--printcmd"])
        .status()
        .expect("failed to get command status");

    assert!(ns.success());
}
