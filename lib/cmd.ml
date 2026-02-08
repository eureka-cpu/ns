(** Functions and operators used in running commands *)
module Cmd = struct
  open Util.Util

  type strategy =
    { workdir : string
    ; primary : Bos.Cmd.t
    ; fallback : Bos.Cmd.t option
    }

  (** Pipe-arg operator, used in adding arguments to a command *)
  let ( |>+ ) cmd = function
    | [] -> cmd
    | [ arg ] -> Bos.Cmd.add_arg cmd arg
    | args -> List.fold_left (fun cmd arg -> Bos.Cmd.add_arg cmd arg) cmd args
  ;;

  let nix_develop entrypoint attribute force_experimental_features =
    Bos.Cmd.v "nix"
    |>+ [ "develop" ] @ [ Uri.sprintf_uri_attr_opt entrypoint attribute ]
    |>+ Option.value ~default:[] force_experimental_features
    |>+ [ "--command"; Unix.shell ]
  ;;

  let legacy_nix_shell_from_entrypoint entrypoint attribute =
    Bos.Cmd.v "nix-shell"
    |>+ Option.value ~default:[] (Option.map (fun attr -> [ "--attr"; attr ]) attribute)
    |>+ [ entrypoint ]
    |>+ [ "--command"; Unix.shell ]
  ;;

  let nix_shell installables force_experimental_features =
    Bos.Cmd.v "nix"
    |>+ [ "shell" ]
    |>+ installables
    |>+ Option.value ~default:[] force_experimental_features
  ;;

  let legacy_nix_shell_from_installables installables =
    (* Need to combine/validate that the installables given are all Nixpkgs *)
    Bos.Cmd.v "nix-shell"
    |>+ [ "--packages" ] @ installables
    |>+ [ "--command"; Unix.shell ]
  ;;

  let print_strategy ({ workdir; primary; fallback } : strategy) =
    print_endline
      (Printf.sprintf
         "'cd' '%s'\n%s\n%s"
         workdir
         (Bos.Cmd.to_string primary)
         (Option.value ~default:"'None'" (Option.map Bos.Cmd.to_string fallback)))
  ;;

  let execute_strategy ({ workdir; primary; fallback } : strategy) =
    Unix.cd workdir;
    match Bos.OS.Cmd.run_status primary with
    | Ok (`Exited 0) -> () (* success, nothing else to do *)
    | Ok (`Exited code | `Signaled code) ->
      (* primary failed *)
      (match fallback with
       | Some fallback ->
         (* show primary error but don't exit *)
         Printf.eprintf "primary command failed (exit %d), trying fallback\n%!" code;
         (match Bos.OS.Cmd.run_status fallback with
          | Ok (`Exited 0) -> ()
          | Ok (`Exited code | `Signaled code) -> exit code
          | Error (`Msg msg) ->
            prerr_endline msg;
            exit 1)
       | None -> exit code)
    | Error (`Msg msg) ->
      (* primary couldn't even be spawned *)
      prerr_endline msg;
      (match fallback with
       | Some fallback ->
         (match Bos.OS.Cmd.run_status fallback with
          | Ok (`Exited 0) -> ()
          | Ok (`Exited code | `Signaled code) -> exit code
          | Error (`Msg msg) ->
            prerr_endline msg;
            exit 1)
       | None -> exit 1)
  ;;
end
