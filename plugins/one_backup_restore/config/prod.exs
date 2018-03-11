use Mix.Config

config :unbrella, :plugins, one_backup_restore: [
  keys_path: "/var/lib/infinity_one/keys",
  config_dirname: "/etc/asterisk/infinity_one/"
]
