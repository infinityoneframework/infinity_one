use Mix.Config

config :unbrella, :plugins, ucc_chat: [
  module: UccChat,
  application: UccChat.Application,
  schemas: [UccChat.Accounts.Account, UccChat.Accounts.User],
  router: UccChatWeb.Router,
  page_size: 76,
  defer: true,
  emoji_one: [
    ascii: true,
    wrapper: :span,
    id_class: "emojione-"
  ]
]

config :ucx_ucc, UccChat.Robot, [
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

import_config "#{Mix.env}.exs"
