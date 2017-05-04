# defmodule UccChat.Mixfile do
#   use Mix.Project

#   def project do
#     # [app: :ucc_chat,
#     [app: :ucx_ucc,
#      version: "0.0.1",
#      elixir: "~> 1.4",
#      build_path: "../../_build",
#      config_path: "../../config/config.exs",
#      deps_path: "../../deps",
#      lockfile: "../../mix.lock",
#      elixirc_paths: elixirc_paths(Mix.env),
#      compilers: [:phoenix, :gettext] ++ Mix.compilers,
#      start_permanent: Mix.env == :prod,
#      # build_embedded: true,
#      aliases: aliases(),
#      deps: deps()]
#   end

#   # Configuration for the OTP application.
#   #
#   # Type `mix help compile.app` for more information.
#   def application do
#     # [mod: {UccChat.Application, []},
#     [
#      extra_applications: [:logger, :runtime_tools, :ucx_ucc]]
#   end

#   # Specifies which paths to compile per environment.
#   defp elixirc_paths(:test), do: ["lib", "test/support"]
#   defp elixirc_paths(_),     do: ["lib", "../../lib"]

#   # Specifies your project dependencies.
#   #
#   # Type `mix help deps` for examples and options.
#   defp deps do
#     [
#       {:phoenix, github: "phoenixframework/phoenix", override: true},
#       {:phoenix_pubsub, "~> 1.0"},
#       {:phoenix_ecto, "~> 3.2"},
#       {:mariaex, ">= 0.0.0"},
#       {:phoenix_html, "~> 2.6"},
#       {:phoenix_live_reload, "~> 1.0", only: :dev},
#       {:gettext, "~> 0.11"},
#       {:cowboy, "~> 1.0"},
#       {:arc_ecto, "~> 0.6.0"},
#       {:auto_linker, "~> 0.1"},
#       {:link_preview, "~> 1.0.0"},
#       {:cowboy, "~> 1.0"},
#       {:mogrify, "~> 0.4.0"},
#       {:tempfile, "~> 0.1.0"},
#       {:phoenix_html, "~> 2.6"},
#       {:unbrella, path: "../../../unbrella"},
#       {:coherence, github: "smpallen99/coherence", branch: "phx-1.3"},
#       {:hackney, "~> 1.8", override: true}
#     ]
#   end

#   # Aliases are shortcuts or tasks specific to the current project.
#   # For example, to create, migrate and run the seeds file at once:
#   #
#   #     $ mix ecto.setup
#   #
#   # See the documentation for `Mix` for more info on aliases.
#   defp aliases do
#     ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
#      "ecto.reset": ["ecto.drop", "ecto.setup"],
#      "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
#   end
# end

