defmodule UcxUcc.Mixfile do
  use Mix.Project

  def project do
    [app: :ucx_ucc,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {UcxUcc.Application, []},
     extra_applications: extra_applications(Mix.env)]
  end
  defp extra_applications(:prod), do: [:logger, :runtime_tools, :coherence]
  defp extra_applications(_), do: extra_applications(:prod) ++ [:faker_elixir_octopus]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["plugins", "lib", "test/support"]
  defp elixirc_paths(_),     do: ["plugins", "lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      # {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:mariaex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:phoenix_haml, "~> 0.2"},
      {:unbrella, path: "../unbrella"},
      {:coherence, github: "smpallen99/coherence", branch: "phx-1.3"},
      {:faker_elixir_octopus, "~> 1.0", only: [:dev, :test]},
      {:cowboy, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "unbrella.migrate", "unbrella.seed"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     "test": ["ecto.create --quiet", "unbrella.migrate", "test"]]
  end
end
