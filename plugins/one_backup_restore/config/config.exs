use Mix.Config

config :unbrella, :plugins, one_backup_restore: [
  module: OneBackupRestore,
  application: OneBackupRestore.Application,
]

import_config "#{Mix.env}.exs"
