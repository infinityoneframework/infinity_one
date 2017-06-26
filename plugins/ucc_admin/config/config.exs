# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :ucc_admin, UccAdmin.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6OzAIK4W+t5VZH++8or9had84n06/j7c43j9Anj0fwObZ9D/klM/A5eA1o23EUcy",
  render_errors: [view: UccAdmin.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: UccAdmin.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"


config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

import_config "talon.exs"

