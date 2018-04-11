use Mix.Config

config :unbrella, :plugins, one_wiki: [
  module: OneWiki,
  schemas: [OneWiki.Accounts.User]
]
