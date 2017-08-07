use Mix.Config

config :unbrella, :plugins, webrtc_client: [
  module: WebrtcClient,
  application: WebrtcClient.Application,
  # schemas: [UccChat.Accounts.Account, UccChat.Accounts.User],
  router: UccChatWeb.Router,
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
