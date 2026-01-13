module Cmd = struct
  open Bos

  let builder cmd = Cmd.v cmd

  (** Pipe-arg operator, used in adding arguments to a command *)
  let ( |>+ ) cmd = function
    | [] -> cmd
    | [ arg ] -> Cmd.add_arg cmd arg
    | args -> List.fold_left (fun cmd arg -> Cmd.add_arg cmd arg) cmd args
  ;;

  let run cmd = OS.Cmd.run cmd
end
