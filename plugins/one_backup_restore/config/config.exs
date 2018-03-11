use Mix.Config

config :unbrella, :plugins, one_backup_restore: [
  module: OneBackupRestore,
]

import_config "#{Mix.env}.exs"
