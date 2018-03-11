use Mix.Config

config :unbrella, :plugins, one_chat: [
  module: OneChat,
  application: OneChat.Application,
  schemas: [OneChat.Accounts.Account, OneChat.Accounts.User],
  router: OneChatWeb.Router,
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

config :infinity_one, OneChat.Robot, [
  # adapter: Hedwig.Adapters.Console,
  adapter: OneChat.Robot.Adapters.OneChat,
  name: "bot",
  aka: "/",
  responders: [
    {Hedwig.Responders.Help, []},
    {Hedwig.Responders.Ping, []},
    # {OneChat.Robot.Responders.Hello, []},

    {HedwigSimpleResponders.Slogan, []},
    {HedwigSimpleResponders.ShipIt, %{ extra_squirrels: false }},
    {HedwigSimpleResponders.Time, []},
    {HedwigSimpleResponders.Uptime, []},
    {HedwigSimpleResponders.BeerMe, []},
    {HedwigSimpleResponders.Fishpun, []},
    {HedwigSimpleResponders.Slime, []},
    {HedwigSimpleResponders.Slogan, []},
  ]
]

config :auto_linker, :attributes, ["rebel-channel": "user", "rebel-click": "phone_number"]
# General application configuration
# config :one_chat,
#   ecto_repos: [OneChat.Repo]

# # Configures the endpoint
# config :one_chat, OneChatWeb.Endpoint,
#   url: [host: "localhost"],
#   secret_key_base: "6t0nS1VfAfJly5M6DwTo4u9XNXvbfJulh69nHEbLw7uTFfyCyBEfVGkRw1iEA7eo",
#   render_errors: [view: OneChatWeb.ErrorView, accepts: ~w(html json)],
#   pubsub: [name: OneChat.PubSub,
#            adapter: Phoenix.PubSub.PG2]

# # Configures Elixir's Logger
# config :logger, :console,
#   format: "$time $metadata[$level] $message\n",
#   metadata: [:request_id]

# # Import environment specific config. This must remain at the bottom
# # of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
