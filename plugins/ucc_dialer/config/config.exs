use Mix.Config

config :unbrella, :plugins, ucc_dialer: [
  module: UcxDialer,
  enabled: true,
  dial_translation: "1, NXXNXXXXXX"
]

