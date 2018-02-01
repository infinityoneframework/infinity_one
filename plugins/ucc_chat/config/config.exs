use Mix.Config

config :unbrella, :plugins, ucc_chat: [
  module: UccChat,
  application: UccChat.Application,
  schemas: [UccChat.Accounts.Account, UccChat.Accounts.User],
  router: UccChatWeb.Router,
  page_size: 76,
  defer: true,
  emoji_one: [
    # single_class: "big",
    ascii: true,
    wrapper: :span,
    id_class: "emojione-"
    # src_path: "/images",
    # src_version: "?v=2.2.7",
    # img_type: ".png"
  ]

]

config :ucx_ucc, UccChat.Robot, [
  # adapter: Hedwig.Adapters.Console,
  adapter: UccChat.Robot.Adapters.UccChat,
  name: "bot",
  aka: "/",
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []},
    {UccChat.Robot.Responders.Hello, []},

    {HedwigSimpleResponders.Slogan, []},
    {HedwigSimpleResponders.ShipIt, %{ extra_squirrels: false }},
    {HedwigSimpleResponders.Time, []},
    {HedwigSimpleResponders.Uptime, []},
    {HedwigSimpleResponders.BeerMe, []},
    {HedwigSimpleResponders.Fishpun, []},
    {HedwigSimpleResponders.Slime, []},
    {HedwigSimpleResponders.Slogan, []},
    # {JiraBot, []}
  ]
]

config :auto_linker, :attributes, ["rebel-channel": "user", "rebel-click": "phone_number"]
# General application configuration
# config :ucc_chat,
#   ecto_repos: [UccChat.Repo]

# # Configures the endpoint
# config :ucc_chat, UccChatWeb.Endpoint,
#   url: [host: "localhost"],
#   secret_key_base: "6t0nS1VfAfJly5M6DwTo4u9XNXvbfJulh69nHEbLw7uTFfyCyBEfVGkRw1iEA7eo",
#   render_errors: [view: UccChatWeb.ErrorView, accepts: ~w(html json)],
#   pubsub: [name: UccChat.PubSub,
#            adapter: Phoenix.PubSub.PG2]

# # Configures Elixir's Logger
# config :logger, :console,
#   format: "$time $metadata[$level] $message\n",
#   metadata: [:request_id]

# # Import environment specific config. This must remain at the bottom
# # of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
