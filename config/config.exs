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
config :ucx_ucc, UcxUcc.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wsFrikxHW07+ALSOPyI681jvpAdnRTQHyrfCwfd0gQlIEfqKegAvSGTVnaTzVSqH",
  render_errors: [view: UcxUcc.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: UcxUcc.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ucx_ucc, :generators,
  migration: true,
  binary_id: true
  # sample_binary_id: "11111111-1111-1111-1111-111111111111"
config :ucx_ucc, :settings_modules, [
  UccSettings.Settings.Config.General,
  UccSettings.Settings.Config.ChatGceneral,
  UccSettings.Settings.Config.FileUpload,
  UccSettings.Settings.Config.Layout,
  UccSettings.Settings.Config.Message
]

config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: UcxUcc.Accounts.User,
  repo: UcxUcc.Repo,
  module: UcxUcc,
  router: UcxUcc.Web.Router,
  login_field: :username,
  user_token: true,
  use_binary_id: true,
  require_current_password: false,
  messages_backend: UcxUcc.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: {:system, "COH_NAME"},
  email_from_email: {:system, "COH_EMAIL"},
  opts: [:rememberable, :invitable, :authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :confirmable, :registerable]

config :coherence, UcxUcc.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: {:system, "SENDGRID_API_KEY"}
# %% End Coherence Configuration %%

import_config("../plugins/*/config/config.exs")
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
