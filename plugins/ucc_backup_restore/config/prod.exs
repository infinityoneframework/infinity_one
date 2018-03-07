use Mix.Config

config :unbrella, :plugins, ucc_backup_restore: [
  keys_path: "/var/lib/ucx_ucc/keys",
  config_dirname: "/etc/ucx_ucc/"
]
