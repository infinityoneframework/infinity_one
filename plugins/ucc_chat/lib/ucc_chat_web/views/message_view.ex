defmodule UccChatWeb.MessageView do
  @moduledoc """
  Helpers for rendering a message.

  There are many functions in this module to support the complexity of
  rendering messages.

  Some of the message features have not yet been implemented. So there
  are some constant return functions below that will need to be implemented
  when we add the missing features.

  TODO: This module is due for a major clean up.
  """
  use UccChatWeb, :view
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3, tag: 1]

  alias UccChat.{Message, Subscription, AttachmentService}
  alias UccChat.ServiceHelpers, as: Helpers

  require Logger

  def get_reaction_people(reaction, user) do
    UccChat.ReactionService.get_reaction_people_names(reaction, user)
  end

  def file_upload_allowed_media_types do
    ""
  end

  def get_not_subscribed_templ(_mb) do
    %{}
  end

  @doc """
  Get the message attributes for the main message li tag.

  Each message is presented in the web page as a `li` tag with a large
  number of attributes. They are calculated here and a single `<li ...>`
  tag is returned. Note that only the open tag is returned. The template
  contains a closing `</li>` tag.

  This approach was taken because I was not sure how to do it otherwise.
  However, I believe there is a better approach.
  """
  def get_message_wrapper_opts(msg, user) do
    cls =
      ~w(get_sequential get_system get_t get_own get_is_temp get_chat_opts get_custom_class get_new_day)a
      |> Enum.reduce("message background-transparent-dark-hover", fn fun, acc ->
        acc <> apply(__MODULE__, fun, [msg, user])
      end)
      # |> add_new_day(msg, user, opts)
    attrs =
      [
        id: msg.id,
        class: cls,
        "data-username": msg.user.username,
        "data-groupable": msg.is_groupable,
        "data-date": format_date(msg.inserted_at, user),
        "data-timestamp": msg.timestamp,
        "rebel-channel": "room"
      ]
    Phoenix.HTML.Tag.tag(:li, attrs)
  end

  def format_date(%{inserted_at: dt}, user) do
    Helpers.format_date tz_offset(dt, user)
  end

  def format_date(dt, user) do
    Helpers.format_date tz_offset(dt, user)
  end

  def format_timestamp(dt, _user) do
    Message.format_timestamp dt
  end

  def format_time(%{inserted_at: dt}, user) do
    format_time dt, user
  end

  def format_time(dt, user) do
    Helpers.format_time tz_offset(dt, user)
  end

  def format_date_time(%{inserted_at: dt}, user) do
    format_date_time dt, user
  end

  def format_date_time(%Ecto.DateTime{} = dt, user) do
    dt
    |> Ecto.DateTime.to_erl
    |> NaiveDateTime.from_erl!
    |> format_date_time(user)
  end

  def format_date_time(nil, _), do: ""

  def format_date_time(dt, user) do
    Helpers.format_date_time tz_offset(dt, user)
  end

  def format_edited_date_time(%{updated_at: dt}, user) do
    format_date_time dt, user
  end

  def tz_offset(dt, user) do
    Timex.shift(dt, hours: user.tz_offset || 0)
  end

  def avatar_from_message(message) do
    avatar = message.avatar
    if is_binary(avatar) and String.length(avatar) > 0 do
      avatar
    else
      false
    end
  end

  def avatar_from_username(_message) do
    Logger.warn "deprecated"
    false
  end

  def emoji(_msg) do
    false
  end

  def get_username(msg), do: msg.user.username
  def get_users_typing(_msg), do: []
  def get_users_typing(_msg, _cmd), do: []
  def alias?(_msg), do: false
  def role_tags(message) do
    if UccSettings.display_roles() do
      message.user_id
      |> Helpers.get_user!
      |> UcxUcc.Accounts.User.tags(message.channel_id)
    else
      []
    end
  end
  def is_bot(_msg), do: false
  def get_date_time(msg, user), do: format_date_time(msg, user)
  def get_time(msg, user), do: format_time(msg, user)
  def is_private(%{type: "p"}), do: true
  def is_private(_msg), do: false
  def hide_cog(_msg), do: ""
  def attachments(_msg), do: []
  def hide_action_links(_msg), do: " hidden"
  def action_links(_msg), do: []
  def hide_reactions(msg) do
    if msg.reactions == [], do: " hidden", else: ""
  end
  def reactions(_msg), do: []
  def mark_user_reaction(_reaction), do: ""
  def render_emoji(_emoji), do: ""
  def has_oembed(_msg), do: false
  def edited(%{edited_id: edited_id} = msg, user) when not is_nil(edited_id) do
    %{
      edit_time: format_edited_date_time(msg, user),
      edited_by: msg.edited_by.username,
    }
  end
  def edited(_msg, _), do: false

  def get_new_day(%{new_day: true}, _), do: " new-day"
  def get_new_day(_, _), do: ""
  def get_sequential(%{sequential: true}, _), do: " sequential"
  def get_sequential(_, _), do: ""
  def get_system(%{system: true}, _), do: " system"
  def get_system(%{type: "p"}, _), do: " system"
  def get_system(_, _), do: ""
  def get_t(%{t: t}, _), do: "#{t}"
  def get_t(_, _), do: ""
  def get_own(%{system: true}, _), do: ""
  def get_own(%{user_id: id}, %{id: id}), do: " own"
  def get_own(_, _), do: ""
  def get_is_temp(%{is_temp: is_temp}, _), do: "#{is_temp}"
  def get_is_temp(_, _), do: ""
  def get_chat_opts(%{chat_opts: chat_opts}, _), do: "#{chat_opts}"
  def get_chat_opts(_, _), do: ""
  def get_custom_class(%{custom_class: custom_class}, _), do: "#{custom_class}"
  def get_custom_class(_, _), do: ""

  def get_info_class(%{system: _}), do: "color-info-font-color"
  def get_info_class(_), do: ""

  def get_mb(chatd) do
    defaults =
      [:blocked?, :read_only?, :archived?, :allowed_to_send?,
        :subscribed?, :can_join?]
      |> Enum.map(&({&1, false}))
      |> Enum.into(%{})

    channel = chatd.channel
    private = channel.type != 0

    blocked = channel.blocked
    read_only = channel.read_only
    archived = channel.archived

    nm = chatd.active_room[:display_name]
    symbol = if channel.type == 2, do: "@" <> nm, else: "#" <> nm

    settings =
      [
        blocked?: blocked,
        read_only?: read_only,
        archived?: archived,
        allowed_to_send?: !(blocked or read_only or archived),
        can_join?: !(private or read_only or blocked or archived),
        subscribed?: Subscription.subscribed?(chatd.channel.id, chatd.user.id),
        symbol: symbol
      ]
      |> Enum.into(defaults)

    config = UccSettings.get_all

    settings =
      [
        max_message_length: UccSettings.max_allowed_message_size(config),
        show_formatting_tips?: UccSettings.show_formatting_tips(config),
        show_file_upload?: AttachmentService.allowed?(channel),
      ]
      |> Enum.into(settings)

    if Application.get_env :ucx_chat, :defer, true do
      [:show_mark_down?, :show_markdown_code?, :show_markdown?]
      # [:katex_syntax?, :show_mark_down?, :show_markdown_code?, :show_markdown?]
      # [:katex_syntax?, :show_mark_down?, :show_markdown_code?, :show_markdown?]
    else
      [:katex_syntax?,
       :show_sandstorm?, :show_location?, :show_mic?, :show_v_rec?,
       :show_mark_down?, :show_markdown_code?, :show_markdown?]
    end
    |> Enum.map(&({&1, true}))
    |> Enum.into(settings)
    # - if nst[:template] do
    # = render nst[:template]
    # - if nst[:can_join] do
    # = nst[:room_name]
    # - if nst[:join_code_required] do
  end

  def show_formatting_tips(%{show_formatting_tips?: true} = mb) do
    content_tag :div, class: "formatting-tips", "aria-hidden": "true", dir: "auto" do
      [
        show_markdown1(mb),
        show_markdown_code(mb),
        show_katax_syntax(mb),
        show_markdown2(mb)
      ]
    end
  end
  def show_formatting_tips(_), do: ""

  def show_katax_syntax(%{katex_syntax?: true}) do
    content_tag :span do
      content_tag :a, href: "https://github.com/Khan/KaTeX/wiki/Function-Support-in-KaTeX", target: "_blank" do
        "\[KaTex\]"
      end
    end
  end
  def show_katax_syntax(_), do: []

  def show_markdown1(%{show_mark_down?: true}) do
    [
      content_tag(:b, "*bold*"),
      content_tag(:i, "_italics_"),
      content_tag(:span, do: ["~", content_tag(:strike, "strike"), "~"])
    ]
  end
  def show_markdown1(_), do: []

  def show_markdown2(%{show_mark_down?: true}) do
    content_tag :q do
      [ hidden_br(), ">quote" ]
    end
  end
  def show_markdown2(_), do: []

  def show_markdown_code(%{show_markdown_code?: true}) do
    [
      content_tag(:code, [class: "code-colors inline"], do: "`inline_code`"),
      show_markdown_code1()
    ]
  end
  def show_markdown_code(_), do: []

  def show_markdown_code1 do
    content_tag :code, class: "code-colors inline" do
      [
        hidden_br(),
        "```",
        hidden_br(),
        content_tag :i,  class: "icon-level-down" do
        end,
        "multi",
        hidden_br(),
        content_tag :i,  class: "icon-level-down" do
        end,
        "line",
        hidden_br(),
        content_tag :i,  class: "icon-level-down" do
        end,
        "```"
      ]
    end
  end


  defp hidden_br do
    content_tag :span, class: "hidden-br" do
      tag :br
    end
  end

  def is_popup_open(%{open: true}), do: true
  def is_popup_open(_), do: false

  def get_popup_cls(_chatd) do
    ""
  end
  def get_loading(_chatd) do
    false
  end
  def get_popup_title(%{title: title}), do: title
  def get_popup_title(_), do: false

  def get_popup_data(%{data: data}), do: data
  def get_popup_data(_), do: false

  def md_key, do: Application.get_env(:ucx_ucc, :markdown_key, "!md")

  @doc """
  Get the configured options for processing the message body.

  Returns a keyword list of the options.

  * md_key - The message tag to mark a block as markdown formatted text
  * message_replacement_patterns - A compiled version of Regex translations
  """
  def message_opts do
    [md_key: md_key(), message_replacement_patterns: compile_message_replacement_patterns()]
  end

  defp compile_message_replacement_patterns do
    :ucx_ucc
    |> Application.get_env(:message_replacement_patterns, [])
    |> Enum.reduce([], fn {re, sub}, acc ->
      case Regex.compile re do
        {:ok, re} -> [{re, sub} | acc]
        _         -> acc
      end
    end)
  end

  @doc """
  Format the message body.

  Processes the message body for:

  * html escaping
  * encoding mention links
  * encoding room links
  * converting emoji short cuts to images
  * running configurable Regex replacement patterns
  * Converting newlines to <br/>
  * Adding markup to quoted code
  * Processing built-in markup like ~strike~ formatting
  """
  def format_message_body(message, opts \\ []) do
    body = message.body || ""
    md_key = Keyword.get(opts, :md_key, md_key())
    message_replacement_patterns = opts[:message_replacement_patterns] || compile_message_replacement_patterns()

    markdown? = md_key && String.contains?(body, md_key)
    quoted? = String.contains?(body, "```") && !markdown?

    body
    |> html_escape(!message.system)
    |> autolink()
    |> encode_mentions
    |> encode_room_links
    |> EmojiOne.shortname_to_image(single_class: "big")
    |> message_formats(markdown?)
    |> run_message_replacement_patterns(message_replacement_patterns)
    |> run_markdown(markdown?, md_key)
    |> format_newlines(quoted? || markdown?, message.system)
    |> UccChatWeb.SharedView.format_quoted_code(quoted? && !markdown?, message.system)
    |> raw
  end

  defp html_escape(body, true) do
    body
    |> Phoenix.HTML.html_escape
    |> Phoenix.HTML.safe_to_string
  end
  defp html_escape(body, _), do: body

  def run_message_replacement_patterns(body, [_ | _] = patterns) do
    Enum.reduce(patterns, body, fn {re, sub}, body ->
      Regex.replace(re, body, sub)
    end)
  end

  def run_message_replacement_patterns(body, _), do: body

  defp autolink(body, opts \\ [])
  defp autolink(body, false), do: body
  defp autolink(body, opts) do
    AutoLinker.link(body, Keyword.put(opts, :exclude_patterns, ["```"]))
  end

  def run_markdown(body, false, _), do: body
  def run_markdown(body, true, md_key) do
    case String.split(body, md_key) do
      [first, markdown | rest] ->
        markdown = String.trim_leading(markdown, "\n")
        first <> ~s|<div class="markdown-body">| <>
          Earmark.as_html!(markdown, %Earmark.Options{gfm: true, plugins: %{"" => UcxUcc.EarmarkPlugin.Task}})
          <> "</div>" <> String.trim_leading(Enum.join(rest, ""))
      _ ->
        body
    end
  end

  def encode_mentions(body) do
    Regex.replace ~r/(^|\s)@([\.a-zA-Z0-9-_]+)/, body,
      ~s'\\1<a rebel-channel="user" rebel-click="flex_call" data-id="members-list"' <>
      ~s' data-fun="flex_user_open" class="mention-link" data-username="\\2">@\\2</a>'
  end

  def encode_room_links(body) do
    Regex.replace ~r/(^|\s)#([\w]+)/, body, ~s'\\1<a class="mention-link" data-channel="\\2">#\\2</a>'
  end

  def message_formats(body, false) do
    body
    |> italic_formats()
    |> bold_formats()
    |> strike_formats()
  end
  def message_formats(body, _), do: body

  defp italic_formats(body) do
    if body =~ ~r/(\<.*?_.*?_.*?\>)|`|!md/ do
      body
    else
      String.replace(body, ~r/_([^\<\>]+?)_/, "<i>\\1</i>")
    end
  end
  defp bold_formats(body) do
    if body =~ ~r/\<.*?\*.*?\*.*?\>|`|!md/ do
      body
    else
      String.replace(body, ~r/\*([^\<\>]+?)\*/, "<strong>\\1</strong>")
    end
  end
  defp strike_formats(body) do
    if body =~ ~r/\<.*?~.*?~.*?\>|`|!md/ do
      body
    else
      String.replace(body, ~r/\~([^\<\>]+?)\~/, "<strike>\\1</strike>")
    end
  end

  defp format_newlines(string, true, _), do: string
  defp format_newlines(string, _, true), do: string
  defp format_newlines(string, false, _), do: String.replace(string, "\n", "\n<br />\n")

  def message_cog_action_li(name, title, icon, extra \\ "") do
    #{}"reaction-message", "Reactions", "people-plus")
    opts = [class: "#{name} #{extra} message-action",
      title: title, "data-id": name] ++ rebel_event(name)

    content_tag :li, opts do
      content_tag :i, class: "icon-#{icon}", "aria-label": title do
        ""
      end
    end
  end

  defp rebel_event("reaction-message"), do: ["rebel-click": "reaction_open"]
  defp rebel_event("delete-message"), do: ["rebel-click": "message_action"]
  defp rebel_event(_), do: ["rebel-click": "message_action"]

  def system_message(message) do
    messages = %{
      "You have been muted and cannot speak in this room" => ~g(You have been muted and cannot speak in this room),
      "You are not authorized to create a message" => ~g(You are not authorized to create a message),
    }
    messages[message] || ~g(Invalid Message Lookup)
  end

end
