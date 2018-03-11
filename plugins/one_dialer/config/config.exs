use Mix.Config

config :unbrella, :plugins, one_dialer: [
  module: UcxDialer,
  enabled: true,
  dial_translation: "1, NXXNXXXXXX"
]

