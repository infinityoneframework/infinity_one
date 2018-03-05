defmodule UcxUcc.Mixfile do
  use Mix.Project

  def project do
    [app: :ucx_ucc,
     version: "0.3.1",
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     start_permanent: Mix.env == :prod,
     docs: [
      extras: ["README.md"],
      main: "UcxUcc",
      groups_for_modules: groups_for_modules()
     ],
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
      {:phoenix, "~> 1.3", override: true},
      {:ecto, "~> 2.1.6", override: true},
      # {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:mariaex, ">= 0.0.0", only: [:dev, :prod]},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.13"},
      # {:phoenix_haml, "~> 0.2"},
      {:unbrella, github: "smpallen99/unbrella"},
      # {:unbrella, path: "../unbrella"},
      {:coherence, github: "smpallen99/coherence", branch: "ucc_save"},
      # {:coherence, path: "../coherence3"},
      {:faker_elixir_octopus, "~> 1.0", only: [:dev, :test]},
      {:arc_ecto, "~> 0.7.0"},
      # {:auto_linker, "~> 0.2"},
      {:auto_linker, github: "smpallen99/auto_linker"},
      # {:auto_linker, path: "../auto_linker"},
      {:link_preview, "~> 1.0.0"},
      {:cowboy, "~> 1.0"},
      {:mogrify, "~> 0.5", override: true},
      {:tempfile, "~> 0.1.0"},
      # {:calliope, "== 0.4.1", override: true},
      {:hackney, "~> 1.9", override: true},
      {:httpoison, "~> 0.13", override: true},
      {:poison, "3.1.0", override: true},
      # TODO: move this to the chat package
      {:hedwig, github: "hedwig-im/hedwig", override: true},
      # {:hedwig, "~> 1.0"},
      {:hedwig_simple_responders, github: "smpallen99/hedwig_simple_responders"},
      # {:hedwig_simple_responders, "~> 0.1.2"},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.5", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:phoenix_slime, "~> 0.9"},
      # {:slime, "~> 1.0", override: true},
      {:slime, github: "smpallen99/slime", override: true},
      # {:slime, "~> 1.0", override: true},
      {:inflex, "~> 1.8"},
      {:postgrex, ">= 0.0.0", only: [:test]},
      # {:rebel, path: "../rebel"},
      {:rebel, github: "smpallen99/rebel"},
      {:exactor, "~> 2.2", override: true},
      {:sqlite_ecto2, "~> 2.0"},
      {:floki, "~> 0.0", override: true},
      {:phoenix_markdown, "~> 0.1"},
      {:distillery, "~> 1.4"},
      {:conform, "~> 2.5"},
      {:ex_syslogger, github: "smpallen99/ex_syslogger"},
      {:gen_smtp, "~> 0.12.0"},
      {:exprof, "~> 0.2.0"},
      # {:scrivener_ecto, path: "../scrivener_ecto"}
      {:scrivener_ecto, github: "smpallen99/scrivener_ecto"},
      {:ex_doc, "~> 0.18", only: :dev},

    ] ++ plugin_deps()
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
     "test": ["ecto.create --quiet", "unbrella.migrate", "test", "unbrella.test"]]
     # # Use the following option if you want to run specific test files
     #"test": ["ecto.create --quiet", "unbrella.migrate", "test"]]
  end

  defp plugin_deps do
    "plugins/*/deps.exs"
    |> Path.wildcard
    |> Enum.reduce([], fn fname, acc ->
      {deps, _} = Code.eval_file fname
      acc ++ deps
    end)
  end

  defp groups_for_modules do
    [
      "Authentication": [ ~r/Coherence.*/ ],
      "Chat Models & Contexts": [
        UccChat.Attachment, UccChat.Channel, UccChat.Direct, UccChat.Emoji,
        UccChat.Mention, UccChat.Message, UccChat.Mute, UccChat.Notification,
        UccChat.NotificationSetting, UccChat.PinnedMessage, UccChat.Reaction,
        UccChat.StarredMessage, UccChat.Subscription, ~r/UccChat.Schema.*/,
        UccChat.Accounts, ~r/UccChat.Accounts\.*/
      ],
      "Chat Settings": [ ~r/UccChat.Settings*/ ],
      "Chat Services": [ ~r/UccChat.*Service/ ],
      "Chat": [
        UccChat, UccChat.AppConfig, UccChat.Application, UccChat.ChannelMonitor,
        UccChat.ChatConstants, UccChat.ChatDat, UccChat.Console, ~r/EmojiOne*/,
        UccChat.Hooks, UccChat.MessageAgent, UccChat.PresenceAgent, UccChat.Robot,
        UccChat.Shared, UccChat.SlashCommands, UccChat.TypingAgent,
        UccChat.AccountNotification, ~r/UccChat.File.*/, ~r/UccChat.Robot.*/,
        ~r"UccChatWeb.*"
      ],
      "UccAdmin": [ ~r/UccAdmin.*/ ],
      "Ucc Dialer": [ ~r/UccDialer*/ ],
      "Ucc Settings": [ ~r/UccSettings*/ ],
      "Ucc Webrtc": [ ~r/UccWebrtc.*/ ],
      "Ucc UI Flex Tab": [ ~r/UccUiFlexTab.*/ ],
      "Mscs": [ ~r/Mscs.*/, Tn, ~r/Unistim.*/ ],
      "Ucx Adapter": [ ~r/UcxAdapter.*/, ~r/Ucx.Cert.*/ ],
      "Ucx Presence": [ ~r/UcxPresence.*/ ]
    ]
  end
end
