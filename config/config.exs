# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ucx_ucc,
  ecto_repos: [UcxUcc.Repo]

# Configures the endpoint
config :ucx_ucc, UcxUccWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wsFrikxHW07+ALSOPyI681jvpAdnRTQHyrfCwfd0gQlIEfqKegAvSGTVnaTzVSqH",
  render_errors: [view: UcxUccWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: UcxUccWeb.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ucx_ucc, :generators,
  migration: true,
  binary_id: true
  # sample_binary_id: "11111111-1111-1111-1111-111111111111"

# The example below replaces [UCX-123] with
# [UCX-123](https://emetrotel.atlassian.net/browse/UCX-123) before
# passing the translated text to the markdown processor
# Additional patterns can be added with the corresponding first and
# third arguments to Regex.replace/3.
#   The first element is the string version of the regex
#   The second element is the replacement string using captures
# config :ucx_ucc, :message_replacement_patterns, [
#   {~S"\[(UCX-\d+)\]([^\(]|$|\n)", "[\\1](https://emetrotel.atlassian.net/browse/\\1)\\2"}
# ]

config :ucx_ucc, :settings_modules, [
  UcxUcc.Settings.General,
  UccChat.Settings.ChatGeneral,
  UccChat.Settings.FileUpload,
  UccChat.Settings.Layout,
  UccChat.Settings.Message,
  UccWebrtc.Settings.Webrtc,
]

config :phoenix, :template_engines,
  # haml: PhoenixHaml.Engine,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine,
  md:   PhoenixMarkdown.Engine

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: UcxUcc.Accounts.User,
  repo: UcxUcc.Repo,
  module: UcxUcc,
  web_module: UcxUccWeb,
  router: UcxUccWeb.Router,
  login_field: :username,
  user_token: true,
  use_binary_id: true,
  require_current_password: false,
  messages_backend: UcxUccWeb.Coherence.Messages,
  logged_out_url: "/",
  layout: {UcxUccWeb.Coherence.LayoutView, "app.html"},
  email_from_name: {:system, "COH_NAME"},
  email_from_email: {:system, "COH_EMAIL"},
  opts: [:rememberable, :invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :confirmable, :registerable]
  # opts: [:rememberable, :invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :confirmable, :registerable]

config :coherence, UcxUccWeb.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: {:system, "SENDGRID_API_KEY"}
# %% End Coherence Configuration %%

config :slime, :keep_lines, true

config :auto_linker, opts: [phone: true, markdown: true]

config :distillery,
  no_warn_missing: [
    :exjsx,
    :postgrex
  ]

import_config("../plugins/*/config/config.exs")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

if File.exists? Path.join("config", "unbrella.exs") do
  import_config Path.join("config", "unbrella.exs")
end
