let color_mode =
  Option.value
    ~default:"auto"
    (Option.map
       (fun force -> if force = "1" then "always" else "never")
       (Sys.getenv_opt "CLICOLOR_FORCE"))
;;

let cmd = Printf.sprintf {| sh -c ./test_ns --color=%s --no-capture |} color_mode in
exit (Sys.command cmd)
