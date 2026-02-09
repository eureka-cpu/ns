open Error

(** Utility types and functions *)
module Util = struct
  (* *)

  (** Functions for interacting with unix filesystems. *)
  module Unix = struct
    (* *)

    (** Return the absolute path or else exit with the underlying {!type:Unix.Error} *)
    let realpath relative_dir =
      try Unix.realpath relative_dir with
      | Unix.Unix_error (e, _, _) ->
        Error.handle_ns_error "%s" (Error.sprintf_unix_error e relative_dir)
    ;;

    (** Change directories or else exit with the underlying {!type:Unix.Error} *)
    let cd path =
      try Unix.chdir path with
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

  (** Types and functions for parsing, interacting and formatting URIs. *)
  module Uri = struct
    (* *)

    (** A local reference to nixpkgs, eg. {nixpkgs#...} or {pkgs#...} (which resolves to the former) *)
    type nixpkgs =
      { uri : string
      ; installables : string list
      }

    (** URI variants, like {/path/to/flake#drv} or {github:NixOS/nixpkgs#drv} *)
    type uri =
      (* A path with up to one attribute, eg. /path/to/resouce or /path/to/resource#... *)
      | LocalResourceMaybeAttr of string * string option
      (* A path with multiple attributes, eg. /path/to/resouce#{...} *)
      | LocalResourceMultiAttr of string * string
      (* A remote resource, eg. github:NixOS/nixpkgs *)
      | RemoteResource of string
      (* A local reference to nixpkgs, eg. nixpkgs#... or pkgs#... (which resolves to the former) *)
      | Nixpkgs of nixpkgs

    (** Format a uri and attribute into a string *)
    let sprintf_uri_attr path attr = Printf.sprintf "%s#%s" path attr

    (** Format a uri and attribute option into a string *)
    let sprintf_uri_attr_opt path attr_opt =
      Option.value
        ~default:path
        (Option.map (fun attr -> sprintf_uri_attr path attr) attr_opt)
    ;;

    (** Convert a {!type:uri} into a string *)
    let uri_to_string uri =
      match uri with
      | LocalResourceMaybeAttr (path, attr_opt) -> sprintf_uri_attr_opt path attr_opt
      | LocalResourceMultiAttr (path, attr) -> sprintf_uri_attr path attr
      | RemoteResource uri -> uri
      | Nixpkgs { uri; _ } -> uri
    ;;

    (** Parse target argument for optional attribute selection *)
    let parse_target target =
      let parse_uri uri attr_opt =
        let is_multiattr maybe_multiattr =
          String.starts_with ~prefix:"{" maybe_multiattr
          && String.ends_with ~suffix:"}" maybe_multiattr
        in
        match String.split_on_char ':' uri with
        | [ "nixpkgs" ] | [ "pkgs" ] ->
          let parse_installables attr_opt =
            match attr_opt with
            | Some attr ->
              if is_multiattr attr
              then (
                match String.split_on_char '{' attr with
                | [ _; rhs ] ->
                  (match String.split_on_char '}' rhs with
                   | [ lhs; _ ] -> String.split_on_char ',' lhs
                   | _ -> [])
                | _ -> [])
              else [ attr ]
            | None -> []
          in
          Nixpkgs
            { uri = sprintf_uri_attr_opt "nixpkgs" attr_opt
            ; installables = parse_installables attr_opt
            }
        | [ path ] ->
          let path = Unix.realpath path in
          (match attr_opt with
           | Some attr ->
             if is_multiattr attr
             then LocalResourceMultiAttr (path, attr)
             else LocalResourceMaybeAttr (path, attr_opt)
           | None -> LocalResourceMaybeAttr (path, attr_opt))
        | _ -> RemoteResource (sprintf_uri_attr_opt uri attr_opt)
      in
      match String.split_on_char '#' target with
      | [ uri ] -> parse_uri uri None
      | [ uri; attr ] -> parse_uri uri (Some attr)
      | _ ->
        Error.handle_ns_error "invalid uri or attribute selection syntax: %s\n%!" target
    ;;

    (** Parse target arguments recursively, returning a list of {!type:uri}.
    This function is tail recursive optimized. *)
    let parse_targets_tr targets =
      let rec parse_targets acc = function
        | [] -> acc
        | target :: remaining -> parse_targets (parse_target target :: acc) remaining
      in
      parse_targets [] targets
    ;;

    let combine_installables_tr installables =
      let rec combine_installables acc = function
        | [] -> Some acc
        | Nixpkgs { installables; _ } :: remaining ->
          combine_installables (acc @ installables) remaining
        | _ -> None
      in
      combine_installables [] installables
    ;;
  end
end
