@moduledoc """
A schema is a keyword list which represents how to map, transform, and validate
configuration values parsed from the .conf file. The following is an explanation of
each key in the schema definition in order of appearance, and how to use them.

## Import

A list of application names (as atoms), which represent apps to load modules from
which you can then reference in your schema definition. This is how you import your
own custom Validator/Transform modules, or general utility modules for use in
validator/transform functions in the schema. For example, if you have an application
`:foo` which contains a custom Transform module, you would add it to your schema like so:

`[ import: [:foo], ..., transforms: ["myapp.some.setting": MyApp.SomeTransform]]`

## Extends

A list of application names (as atoms), which contain schemas that you want to extend
with this schema. By extending a schema, you effectively re-use definitions in the
extended schema. You may also override definitions from the extended schema by redefining them
in the extending schema. You use `:extends` like so:

`[ extends: [:foo], ... ]`

## Mappings

Mappings define how to interpret settings in the .conf when they are translated to
runtime configuration. They also define how the .conf will be generated, things like
documention, @see references, example values, etc.

See the moduledoc for `Conform.Schema.Mapping` for more details.

## Transforms

Transforms are custom functions which are executed to build the value which will be
stored at the path defined by the key. Transforms have access to the current config
state via the `Conform.Conf` module, and can use that to build complex configuration
from a combination of other config values.

See the moduledoc for `Conform.Schema.Transform` for more details and examples.

## Validators

Validators are simple functions which take two arguments, the value to be validated,
and arguments provided to the validator (used only by custom validators). A validator
checks the value, and returns `:ok` if it is valid, `{:warn, message}` if it is valid,
but should be brought to the users attention, or `{:error, message}` if it is invalid.

See the moduledoc for `Conform.Schema.Validator` for more details and examples.
"""
[
  extends: [],
  import: [],
  mappings: [
    "coherence.require_current_password": [
      commented: false,
      datatype: :atom,
      default: false,
      doc: "Provide documentation for coherence.require_current_password here.",
      hidden: false,
      to: "coherence.require_current_password"
    ],
    "coherence.logged_out_url": [
      commented: false,
      datatype: :binary,
      default: "/",
      doc: "Provide documentation for coherence.logged_out_url here.",
      hidden: false,
      to: "coherence.logged_out_url"
    ],
    "coherence.email_from_name": [
      commented: false,
      datatype: :binary,
      default: "Need to set this",
      doc: "Provide documentation for coherence.email_from_name here.",
      hidden: false,
      to: "coherence.email_from_name",
      env_var: "COH_NAME",
    ],
    "coherence.email_from_email": [
      commented: false,
      datatype: :binary,
      default: "Need to set this",
      doc: "Provide documentation for coherence.email_from_email here.",
      hidden: false,
      to: "coherence.email_from_email",
      env_var: "COH_EMAIL"
    ],
    # "coherence.opts": [
    #   commented: false,
    #   datatype: [
    #     list: :atom
    #   ],
    #   default: [
    #     :rememberable,
    #     :invitable,
    #     :authenticatable,
    #     :recoverable,
    #     :lockable,
    #     :trackable,
    #     :unlockable_with_token,
    #     :confirmable,
    #     :registerable
    #   ],
    #   doc: "Provide documentation for coherence.opts here.",
    #   hidden: false,
    #   to: "coherence.opts"
    # ],
    "coherence.Elixir.UcxUccWeb.Coherence.Mailer.adapter": [
      commented: false,
      datatype: :atom,
      default: Swoosh.Adapters.Sendgrid,
      doc: "Provide documentation for coherence.Elixir.UcxUccWeb.Coherence.Mailer.adapter here.",
      hidden: true,
      to: "coherence.Elixir.UcxUccWeb.Coherence.Mailer.adapter"
    ],
    "coherence.Elixir.UcxUccWeb.Coherence.Mailer.api_key": [
      commented: false,
      datatype: :binary,
      default: "Need to set this",
      doc: "Provide documentation for coherence.Elixir.UcxUccWeb.Coherence.Mailer.api_key here.",
      hidden: false,
      to: "coherence.Elixir.UcxUccWeb.Coherence.Mailer.api_key",
      env_var: "SENDGRID_API_KEY"
    ],
    "distillery.no_warn_missing": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :exjsx,
        :postgrex
      ],
      doc: "Provide documentation for distillery.no_warn_missing here.",
      hidden: true,
      to: "distillery.no_warn_missing"
    ],
    "ucx_license_manager.timeout": [
      commented: false,
      datatype: :integer,
      default: 5000,
      doc: "Provide documentation for ucx_license_manager.timeout here.",
      hidden: true,
      to: "ucx_license_manager.timeout"
    ],
    "auto_linker.opts.phone": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for auto_linker.opts.phone here.",
      hidden: false,
      to: "auto_linker.opts.phone"
    ],
    "auto_linker.attributes.rebel-channel": [
      commented: false,
      datatype: :binary,
      default: "user",
      doc: "Provide documentation for auto_linker.attributes.rebel-channel here.",
      hidden: true,
      to: "auto_linker.attributes.rebel-channel"
    ],
    "auto_linker.attributes.rebel-click": [
      commented: false,
      datatype: :binary,
      default: "phone_number",
      doc: "Provide documentation for auto_linker.attributes.rebel-click here.",
      hidden: true,
      to: "auto_linker.attributes.rebel-click"
    ],
    "unbrella.plugins.mscs.base_mac_address": [
      commented: false,
      datatype: :integer,
      default: 87241261056,
      doc: "Provide documentation for unbrella.plugins.mscs.base_mac_address here.",
      hidden: false,
      to: "unbrella.plugins.mscs.base_mac_address"
    ],
    "unbrella.plugins.mscs.unistim_port_base": [
      commented: false,
      datatype: :integer,
      default: 18000,
      doc: "Provide documentation for unbrella.plugins.mscs.unistim_port_base here.",
      hidden: false,
      to: "unbrella.plugins.mscs.unistim_port_base"
    ],
    "unbrella.plugins.mscs.cs_ip": [
      commented: false,
      datatype: :binary,
      default: "127.0.0.1",
      doc: "Provide documentation for unbrella.plugins.mscs.cs_ip here.",
      hidden: false,
      to: "unbrella.plugins.mscs.cs_ip"
    ],
    "unbrella.plugins.mscs.ucxport": [
      commented: false,
      datatype: :integer,
      default: 7000,
      doc: "Provide documentation for unbrella.plugins.mscs.ucxport here.",
      hidden: false,
      to: "unbrella.plugins.mscs.ucxport"
    ],
    "unbrella.plugins.ucc_chat.page_size": [
      commented: false,
      datatype: :integer,
      default: 150,
      doc: "Provide documentation for unbrella.plugins.ucc_chat.page_size here.",
      hidden: false,
      to: "unbrella.plugins.ucc_chat.page_size"
    ],
    "unbrella.plugins.ucc_chat.defer": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for unbrella.plugins.ucc_chat.defer here.",
      hidden: true,
      to: "unbrella.plugins.ucc_chat.defer"
    ],
    "unbrella.plugins.ucc_chat.emoji_one.wrapper": [
      commented: false,
      datatype: :atom,
      default: :span,
      doc: "Provide documentation for unbrella.plugins.ucc_chat.emoji_one.wrapper here.",
      hidden: true,
      to: "unbrella.plugins.ucc_chat.emoji_one.wrapper"
    ],
    "unbrella.plugins.ucc_chat.emoji_one.id_class": [
      commented: false,
      datatype: :binary,
      default: "emojione-",
      doc: "Provide documentation for unbrella.plugins.ucc_chat.emoji_one.id_class here.",
      hidden: true,
      to: "unbrella.plugins.ucc_chat.emoji_one.id_class"
    ],
    "unbrella.plugins.ucc_dialer.enabled": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for unbrella.plugins.ucc_dialer.enabled here.",
      hidden: false,
      to: "unbrella.plugins.ucc_dialer.enabled"
    ],
    "unbrella.plugins.ucc_dialer.dial_translation": [
      commented: false,
      datatype: :binary,
      default: "1, NXXNXXXXXX",
      doc: "Provide documentation for unbrella.plugins.ucc_dialer.dial_translation here.",
      hidden: false,
      to: "unbrella.plugins.ucc_dialer.dial_translation"
    ],
    "unbrella.plugins.ucx_presence.enabled": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for unbrella.plugins.ucx_presence.enabled here.",
      hidden: false,
      to: "unbrella.plugins.ucx_presence.enabled"
    ],
    "ex_ami.logging": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for ex_ami.logging here.",
      hidden: false,
      to: "ex_ami.logging"
    ],
    "ex_ami.servers.asterisk.connection": [
      commented: false,
      datatype: [list: :ip],
      # datatype: {:atom, [list: [atom: :binary, atom: :integer]]},
      default: [{"127.0.0.1", "5038"}],
      # default: {Elixir.ExAmi.TcpConnection, [host: "127.0.0.1", port: 5038]},
      doc: "Provide documentation for ex_ami.servers.asterisk.connection here.",
      hidden: false,
      to: "ex_ami.servers.asterisk.connection",
    ],
    "ex_ami.servers.asterisk.username": [
      commented: false,
      datatype: :binary,
      default: "ucx_ucc",
      doc: "Provide documentation for ex_ami.servers.asterisk.username here.",
      hidden: false,
      to: "ex_ami.servers.asterisk.username"
    ],
    "ex_ami.servers.asterisk.secret": [
      commented: false,
      datatype: :binary,
      default: "emetr0tel",
      doc: "Provide documentation for ex_ami.servers.asterisk.secret here.",
      hidden: false,
      to: "ex_ami.servers.asterisk.secret"
    ],
    "ex_ami.servers.asterisk.logging": [
      commented: false,
      datatype: :atom,
      default: true,
      doc: "Provide documentation for ex_ami.servers.asterisk.logging here.",
      hidden: false,
      to: "ex_ami.servers.asterisk.logging"
    ],
    "logger.level": [
      commented: false,
      datatype: :atom,
      default: :info,
      doc: "Provide documentation for logger.level here.",
      hidden: false,
      to: "logger.level"
    ],
    "logger.backends": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :console
      ],
      doc: "Provide documentation for logger.backends here.",
      hidden: false,
      to: "logger.backends"
    ],
    "logger.console.level": [
      commented: false,
      datatype: :atom,
      default: :warn,
      doc: "Provide documentation for logger.console.level here.",
      hidden: false,
      to: "logger.console.level"
    ],
    "logger.console.format": [
      commented: false,
      datatype: :binary,
      default: """
      [$level] $metadata$message
      """,
      doc: "Provide documentation for logger.console.format here.",
      hidden: false,
      to: "logger.console.format"
    ],
    "logger.console.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :module,
        :function
      ],
      doc: "Provide documentation for logger.console.metadata here.",
      hidden: false,
      to: "logger.console.metadata"
    ],
    "logger.syslog.appid": [
      commented: false,
      datatype: :binary,
      default: "ucx_ucc",
      doc: "Provide documentation for logger.syslog.appid here.",
      hidden: false,
      to: "logger.syslog.appid"
    ],
    "logger.syslog.host": [
      commented: false,
      datatype: :charlist,
      default: '127.0.0.1',
      doc: "Provide documentation for logger.syslog.host here.",
      hidden: false,
      to: "logger.syslog.host"
    ],
    "logger.syslog.facility": [
      commented: false,
      datatype: :atom,
      default: :local5,
      doc: "Provide documentation for logger.syslog.facility here.",
      hidden: false,
      to: "logger.syslog.facility"
    ],
    "logger.syslog.format": [
      commented: false,
      datatype: :binary,
      default: """
      [$level] $metadata$message
      """,
      doc: "Provide documentation for logger.syslog.format here.",
      hidden: false,
      to: "logger.syslog.format"
    ],
    "logger.syslog.metadata": [
      commented: false,
      datatype: [
        list: :atom
      ],
      default: [
        :module,
        :function
      ],
      doc: "Provide documentation for logger.syslog.metadata here.",
      hidden: false,
      to: "logger.syslog.metadata"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.host": [
      commented: false,
      datatype: :binary,
      default: "localhost",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.host here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.host"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.port": [
      commented: false,
      datatype: :integer,
      default: 4021,
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.port here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.url.port"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.port": [
      commented: false,
      datatype: :integer,
      default: 4021,
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.port here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.port"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.otp_app": [
      commented: false,
      datatype: :atom,
      default: :ucx_ucc,
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.otp_app here.",
      hidden: true,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.otp_app"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.keyfile": [
      commented: false,
      datatype: :binary,
      default: "priv/key.pem",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.keyfile here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.keyfile"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.certfile": [
      commented: false,
      datatype: :binary,
      default: "priv/cert.pem",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.certfile here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.https.certfile"
    ],
    "ucx_ucc.Elixir.UcxUccWeb.Endpoint.secret_key_base": [
      commented: false,
      datatype: :binary,
      default: "Z9j5A+lDlf1qG+i2ZhVavb0GKHDLkZb/MH7qVy95FM8s2T0d3AI7WU6gyWipUxVl",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUccWeb.Endpoint.secret_key_base here.",
      hidden: true,
      to: "ucx_ucc.Elixir.UcxUccWeb.Endpoint.secret_key_base"
    ],
    "ucx_ucc.Elixir.UcxUcc.Repo.username": [
      commented: false,
      datatype: :binary,
      default: "root",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUcc.Repo.username here.",
      hidden: true,
      to: "ucx_ucc.Elixir.UcxUcc.Repo.username"
    ],
    "ucx_ucc.Elixir.UcxUcc.Repo.password": [
      commented: false,
      datatype: :binary,
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUcc.Repo.password here.",
      hidden: true,
      to: "ucx_ucc.Elixir.UcxUcc.Repo.password",
      env_var: "REPO_PASSWORD"
    ],
    "ucx_ucc.Elixir.UcxUcc.Repo.database": [
      commented: false,
      datatype: :binary,
      default: "ucx_ucc_prod",
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUcc.Repo.database here.",
      hidden: true,
      to: "ucx_ucc.Elixir.UcxUcc.Repo.database"
    ],
    "ucx_ucc.Elixir.UcxUcc.Repo.test": [
      commented: false,
      datatype: [list: :binary],
      default: ["test", "99"],
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUcc.Repo.test here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUcc.Repo.test"
    ],
    "ucx_ucc.Elixir.UcxUcc.Repo.pool_size": [
      commented: false,
      datatype: :integer,
      default: 15,
      doc: "Provide documentation for ucx_ucc.Elixir.UcxUcc.Repo.pool_size here.",
      hidden: false,
      to: "ucx_ucc.Elixir.UcxUcc.Repo.pool_size"
    ]
  ],
  transforms: [
    "ucx_ucc.Elixir.UcxUcc.Repo.test": fn conf ->
      case Conform.Conf.get(conf, "ucx_ucc.Elixir.UcxUcc.Repo.test") |> IO.inspect(label: "test") do
        [{_, [atom, int]}] ->
          {String.to_atom(atom), String.to_integer(int)}
        _ -> {:test, 20}
      end
    end,
    "ex_ami.servers.asterisk.connection": fn conf ->
      {ip, port} =
        case Conform.Conf.get(conf, "ex_ami.servers.asterisk.connection") do
          [{_, [{ip, port}]}] ->
            {ip, String.to_integer(port)}
          _ ->
            {"127.0.0.1", 5038}
        end

      {Elixir.ExAmi.TcpConnection, [host: ip, port: port]}
    end
  ],
  validators: []
]
