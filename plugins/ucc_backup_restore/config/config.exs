use Mix.Config

config :unbrella, :plugins, ucc_backup_restore: [
  module: UccBackupRestore,
]

import_config "#{Mix.env}.exs"
