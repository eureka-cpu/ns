(** Functions and operators used in running commands *)
module Cmd = struct
  open Bos

  (** Construct a command builder

    Example:
    Cmd.builder "nix" |>+ \[ "flake" "show" "--json" \]
  *)
  let builder cmd = Cmd.v cmd

  (** Pipe-arg operator, used in adding arguments to a command *)
  let ( |>+ ) cmd = function
    | [] -> cmd
    | [ arg ] -> Cmd.add_arg cmd arg
    | args -> List.fold_left (fun cmd arg -> Cmd.add_arg cmd arg) cmd args
  ;;

  (** Run a command

    Example:
    Cmd.run (Cmd.builder "nix" |>+ \[ "show-config" "--json" \])
  *)
  let run cmd = OS.Cmd.run cmd
end
