open Error

module Util = struct
  (** Parse target argument for optional attribute selection *)
  let parse_target maybe_attrpath =
    match String.split_on_char '#' maybe_attrpath with
    | [ dir ] -> dir, None
    | [ dir; devshell ] -> dir, Some devshell
    | _ ->
      Error.handle_ns_error
        "invalid path or attribute selection syntax: %s\n%!"
        maybe_attrpath
  ;;

  (** Get the user's shell from the environment *)
  let get_user_shell =
    match Sys.getenv_opt "SHELL" with
    | Some s -> s
    | None -> "/bin/sh"
  ;;

  (** Whether a flake.nix file exists at the given directory *)
  let flake_exists_at dir = Sys.file_exists (Filename.concat dir "flake.nix")

  (** Whether a shell.nix file exists at the given directory *)
  let shell_exists_at dir = Sys.file_exists (Filename.concat dir "shell.nix")
end
