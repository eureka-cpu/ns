module Cli = struct
  open Cmdliner

  let target_dir =
    let doc = "Target directory with optional attribute" in
    Arg.(required & pos 0 (some dirpath) None & info [] ~docv:"DIR[#ATTR]" ~doc)
  ;;

  let cmd entrypoint =
    let doc = "Enter a nix development shell in the target directory" in
    let info =
      let version = "0.3.0" in
      Cmd.info "ns" ~doc ~version
    in
    Cmd.v info Term.(const entrypoint $ target_dir)
  ;;

  let eval entrypoint = Cmd.eval (cmd entrypoint)
end
