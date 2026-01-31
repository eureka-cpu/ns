let color_mode =
  Option.value
    ~default:"auto"
    (Option.map
       (fun force -> if force = "1" then "always" else "never")
       (Sys.getenv_opt "CLICOLOR_FORCE"))
and cmd color_mode = Printf.sprintf "./test_ns --color=%s --nocapture" color_mode in
let code = Sys.command (cmd color_mode) in
exit code
