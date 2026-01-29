open Error

module Util = struct
  type target =
    | Path of string
    | Uri of string

  (** Parse target argument for optional attribute selection *)
  let parse_target target =
    let parse_uri uri =
      match String.split_on_char ':' uri with
      | [ path ] -> Path path
      | [ _; _ ] -> Uri uri
      | _ -> Error.handle_ns_error "invalid uri: %s\n%!" uri
    in
    match String.split_on_char '#' target with
    | [ uri ] -> parse_uri uri, None
    | [ uri; attr ] -> parse_uri uri, Some attr
    | _ ->
      Error.handle_ns_error "invalid uri or attribute selection syntax: %s\n%!" target
  ;;

  (** Return the absolute path or else exit with the underlying {!type:Unix.Error} *)
  let realpath relative_dir =
    try Unix.realpath relative_dir with
    | Unix.Unix_error (e, _, _) ->
      Error.handle_ns_error "%s" (Error.sprintf_unix_error e relative_dir)
  ;;

  (** Change directories and return the directory entered or else exit with the underlying {!type:Unix.Error} *)
  let cd path =
    try
      Unix.chdir path;
      path
    with
    | Unix.Unix_error (e, _, _) ->
      Error.handle_ns_error "%s" (Error.sprintf_unix_error e path)
  ;;

  (** Get the user's shell from the environment *)
  let shell =
    match Sys.getenv_opt "SHELL" with
    | Some s -> s
    | None -> "/bin/sh"
  ;;

  (** Whether a flake.nix file exists at the given directory *)
  let flake_exists_at dir = Sys.file_exists (Filename.concat dir "flake.nix")

  (** Whether a shell.nix file exists at the given directory *)
  let shell_exists_at dir = Sys.file_exists (Filename.concat dir "shell.nix")
end
