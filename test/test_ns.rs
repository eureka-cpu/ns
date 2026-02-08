use std::{env, path, process, sync};

static DUNE_TEST_DIR: sync::OnceLock<path::PathBuf> = sync::OnceLock::new();
static ENV_SHELL: sync::OnceLock<String> = sync::OnceLock::new();

fn dune_test_dir() -> &'static path::PathBuf {
    DUNE_TEST_DIR.get_or_init(|| env::current_dir().expect("failed to get test directory"))
}
fn env_shell() -> &'static String {
    ENV_SHELL.get_or_init(|| env::var("SHELL").expect("failed to get shell from environment"))
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

fn assert_stdout_eq(stdout: &[u8], expected: &[&[&str]]) {
    let stdout = String::from_utf8_lossy(stdout);
    let stdout: Vec<Vec<String>> = stdout
        .trim_end()
        .split('\n')
        .map(|cmd| {
            let cmd = cmd.replace('\'', "");
            cmd.split_whitespace().map(|cmd| cmd.to_string()).collect()
        })
        .collect();

    if expected != stdout.as_slice() {
        panic!(
            "\nExpected: \x1b[32m{:#?}\x1b[0m\nObserved: \x1b[31m{:#?}\x1b[0m",
            expected,
            stdout.as_slice()
        )
    }
}

mod nix_develop_tests {
    use super::*;

    #[test]
    fn single_arg_no_attr() {
        let output = process::Command::new(ns())
            .args([flake_dir().as_os_str(), "--printcmd".as_ref()])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &flake_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_no_attr_force() {
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &flake_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_single_attr() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &flake_dir().to_string_lossy()],
                &["nix", "develop", &flake_uri, "--command", env_shell()],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_single_attr_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &flake_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_no_attrs() {
        let output = process::Command::new(ns())
            .args([flake_dir().as_os_str(), ".".as_ref(), "--printcmd".as_ref()])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_no_attrs_force() {
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                ".".as_ref(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attr_lhs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, ".", "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "develop", &flake_uri, "--command", env_shell()],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attr_lhs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, ".", "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "develop",
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }
}

mod legacy_nix_shell_tests {
    use super::*;

    #[test]
    fn single_arg_no_attr() {
        let output = process::Command::new(ns())
            .args([shell_dir().as_os_str(), "--printcmd".as_ref()])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &shell_dir().to_string_lossy()],
                &[
                    "nix-shell",
                    &shell_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_no_attr_force() {
        let output = process::Command::new(ns())
            .args([
                shell_dir().as_os_str(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &shell_dir().to_string_lossy()],
                &[
                    "nix-shell",
                    &shell_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_single_attr() {
        let shell_uri = format!("{}#default", shell_dir().display());
        let output = process::Command::new(ns())
            .args([&shell_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &shell_dir().to_string_lossy()],
                &[
                    "nix-shell",
                    "--attr",
                    "default",
                    &shell_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_single_attr_force() {
        let shell_uri = format!("{}#default", shell_dir().display());
        let output = process::Command::new(ns())
            .args([&shell_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &shell_dir().to_string_lossy()],
                &[
                    "nix-shell",
                    "--attr",
                    "default",
                    &shell_dir().to_string_lossy(),
                    "--command",
                    env_shell(),
                ],
                &["None"],
            ],
        );
    }
}

mod nix_shell_tests {
    use super::*;

    #[test]
    fn single_arg_multi_attr() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn single_arg_multi_attr_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attr_rhs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                "--printcmd".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, &flake_dir().to_string_lossy()],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attr_rhs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attrs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_single_attrs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attr_lhs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, ".", "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attr_lhs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, ".", "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attr_rhs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                "--printcmd".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, &flake_dir().to_string_lossy()],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attr_rhs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attrs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn two_args_multi_attrs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs_lhs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([&flake_uri, remote_uri, ".", "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, remote_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs_lhs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([&flake_uri, remote_uri, ".", "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    remote_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs_rhs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                remote_uri.as_ref(),
                "--printcmd".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs_rhs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                remote_uri.as_ref(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, remote_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", remote_uri, &flake_uri, &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_single_attrs_force() {
        let flake_uri = format!("{}#default", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#hello";
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, remote_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs_lhs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([&flake_uri, remote_uri, ".", "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", &flake_uri, remote_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs_lhs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([&flake_uri, remote_uri, ".", "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    &flake_uri,
                    remote_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs_rhs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                remote_uri.as_ref(),
                "--printcmd".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs_rhs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([
                flake_dir().as_os_str(),
                flake_uri.as_ref(),
                remote_uri.as_ref(),
                "--printcmd".as_ref(),
                "--force".as_ref(),
            ])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_dir().to_string_lossy(),
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, remote_uri, "--printcmd"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &["nix", "shell", remote_uri, &flake_uri, &flake_uri],
                &["None"],
            ],
        );
    }

    #[test]
    fn three_args_multi_attrs_force() {
        let flake_uri = format!("{}#{{hello,cowsay}}", flake_dir().display());
        let remote_uri = "github:NixOS/nixpkgs#{hello,cowsay}";
        let output = process::Command::new(ns())
            .args([&flake_uri, &flake_uri, remote_uri, "--printcmd", "--force"])
            .output()
            .expect("failed to get command output");

        assert!(output.status.success());
        assert_stdout_eq(
            &output.stdout,
            &[
                &["cd", &dune_test_dir().to_string_lossy()],
                &[
                    "nix",
                    "shell",
                    remote_uri,
                    &flake_uri,
                    &flake_uri,
                    "--extra-experimental-features",
                    "flakes",
                    "--extra-experimental-features",
                    "nix-command",
                ],
                &["None"],
            ],
        );
    }
}
