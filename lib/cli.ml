module Cli = struct
  open Cmdliner
  open Error

  let target_dir =
    let doc = "Target directory with optional attribute" in
    Arg.(required & pos 0 (some dirpath) None & info [] ~docv:"DIR[#ATTR]" ~doc)
  ;;

  let cmd entrypoint =
    let doc = "Enter a nix development shell in the target directory" in
    let info =
      let version =
        match Build_info.V1.version () with
        | None -> Error.handle_ns_error "missing version information"
        | Some version -> Build_info.V1.Version.to_string version
      in
      Cmd.info "ns" ~doc ~version
    in
    Cmd.v info Term.(const entrypoint $ target_dir)
  ;;

  let eval entrypoint = Cmd.eval (cmd entrypoint)
end
