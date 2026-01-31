use std::{env, path, process, sync};

static DUNE_TEST_DIR: sync::OnceLock<path::PathBuf> = sync::OnceLock::new();

fn dune_test_dir() -> &'static path::PathBuf {
    DUNE_TEST_DIR.get_or_init(|| env::current_dir().expect("failed to get test directory"))
}
fn ns() -> path::PathBuf {
    dune_test_dir()
        .join("..")
        .join("bin")
        .join("main.exe")
        .canonicalize()
        .expect("failed to canonicalize path to ns binary")
}
fn flake_dir() -> path::PathBuf {
    dune_test_dir()
        .join("src")
        .join("flake")
        .canonicalize()
        .expect("failed to canonicalize path to ns binary")
}
fn shell_dir() -> path::PathBuf {
    dune_test_dir()
        .join("src")
        .join("shell")
        .canonicalize()
        .expect("failed to canonicalize path to ns binary")
}

#[test]
fn single_arg_flake_no_attr() {
    let output = process::Command::new(ns())
        .args([flake_dir().as_os_str(), "--printcmd".as_ref()])
        .output()
        .expect("failed to get command output");

    assert!(output.status.success());
}

#[test]
fn single_arg_shell_no_attr() {
    let output = process::Command::new(ns())
        .args([shell_dir().as_os_str(), "--printcmd".as_ref()])
        .output()
        .expect("failed to get command output");

    assert!(output.status.success());
}

#[test]
fn single_arg_flake_single_attr() {
    let flake_uri = format!("{}#default", flake_dir().display());
    let output = process::Command::new(ns())
        .args([flake_uri, "--printcmd".into()])
        .output()
        .expect("failed to get command output");

    assert!(output.status.success());
}

#[test]
fn single_arg_shell_single_attr() {
    let shell_uri = format!("{}#default", shell_dir().display());
    let output = process::Command::new(ns())
        .args([shell_uri, "--printcmd".into()])
        .output()
        .expect("failed to get command output");

    assert!(output.status.success());
}

#[test]
fn single_arg_flake_multi_attr() {
    let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
    let output = process::Command::new(ns())
        .args([flake_uri, "--printcmd".into()])
        .output()
        .expect("failed to get command output");

    assert!(output.status.success());
}
