module Error = struct
  (** Format and report an error and exit with status code 1 *)
  let handle_ns_error fmt =
    Printf.ksprintf
      (fun s ->
         Printf.eprintf "ns: %s%!" s;
         exit 1)
      fmt
  ;;

  (** Format a {!type:Unix.error} into a string with context *)
  let sprintf_unix_error err context =
    Printf.sprintf
      "%s: %s\n%!"
      (String.uncapitalize_ascii (Unix.error_message err))
      context
  ;;
end
