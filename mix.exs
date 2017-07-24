defmodule UcxUcc.Mixfile do
  use Mix.Project

  def project do
    [app: :ucx_ucc,
     version: "0.0.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_apps: [:mix]],
     elixirc_paths: elixirc_paths(Mix.env),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
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
  defp elixirc_paths(:test) do
    paths =
      plugins()
      |> Enum.map(&Path.join(["plugins", &1, "test", "support"]))
      |> List.flatten

    elixirc_paths(nil) ++ ["test/support" | paths]
  end
  defp elixirc_paths(_) do
    paths =
      plugins()
      |> Enum.map(&Path.join(["plugins", &1, "lib"]))
      |> List.flatten()
    paths ++ ["lib"]
  end

  defp plugins do
    "plugins"
    |> File.ls!()
    |> Enum.filter(&File.dir?(Path.join("plugins", &1)))
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      # {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:mariaex, ">= 0.0.0", only: [:dev, :prod]},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:phoenix_haml, "~> 0.2"},
      {:unbrella, github: "smpallen99/unbrella"},
      # {:unbrella, path: "../unbrella"},
      {:coherence, github: "smpallen99/coherence", branch: "phx-1.3"},
      {:faker_elixir_octopus, "~> 1.0", only: [:dev, :test]},
      {:arc_ecto, "~> 0.6.0"},
      {:auto_linker, "~> 0.1"},
      {:link_preview, "~> 1.0.0"},
      {:cowboy, "~> 1.0"},
      {:mogrify, "~> 0.4.0"},
      {:tempfile, "~> 0.1.0"},
      {:calliope, "== 0.4.1", override: true},
      {:hackney, "~> 1.8", override: true},
      {:httpoison, "~> 0.11", override: true},
      # TODO: move this to the chat package
      {:hedwig, "~> 1.0"},
      {:hedwig_simple_responders, "~> 0.1.2"},
      {:ucc_shared, path: "plugins/ucc_shared", app: false},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:phoenix_slime, "~> 0.9"},
      # {:slime, "~> 1.0", override: true},
      {:slime, github: "slime-lang/slime", override: true},
      {:inflex, "~> 1.7"},
      {:arc_ecto, "~> 0.6.0"},
      {:postgrex, ">= 0.0.0", only: :test},
      # {:rebel, path: "../rebel"},
      {:rebel, github: "smpallen99/rebel"},
      # {:ucc_chat, path: "plugins/ucc_chat", app: false},
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
     "commit": ["deps.get --only #{Mix.env}", "dialyzer", "credo --strict"],
     # "test": ["ecto.create --quiet", "unbrella.migrate", "test"]]
     "test": ["ecto.create --quiet", "unbrella.migrate", "test", "unbrella.test"]]
  end
end
