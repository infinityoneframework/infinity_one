defmodule UccChat.ServiceHelpers do
  # use UccChatWeb, :service
  alias UccChat.{
    # Channel, MessageService
    Channel
  }

  require UccChatWeb.SharedView
  use UcxUccWeb.Gettext

  alias UcxUcc.{Repo, Hooks, Accounts.User}

  import Ecto.Query

  @default_user_preload [:account, :roles, user_roles: :role]

  def default_user_preloads, do: Hooks.user_preload(@default_user_preload)

  def get_user!(user, opts \\ [])
  def get_user!(%Phoenix.Socket{assigns: assigns}, opts) do
    get_user!(assigns[:user_id], opts)
  end
  def get_user!(id, opts) do
    preload = user_preload(opts[:preload] || default_user_preloads())
    Repo.one!(from u in User, where: u.id == ^id, preload: ^preload)
  end

  def get_user(user, opts \\ [])
  def get_user(%Phoenix.Socket{assigns: assigns}, opts) do
    get_user(assigns[:user_id], opts)
  end

  def get_user(id, opts) do
    preload = opts[:preload] || default_user_preloads()
    Repo.one(from u in User, where: u.id == ^id, preload: ^preload)
  end

  def get_user_by_name(username, opts \\ [])
  def get_user_by_name(nil, _), do: nil
  def get_user_by_name(username, opts) do
    preload =
      if opts[:preload] == false do
        []
      else
        default_user_preloads()
      end
      |> user_preload

    User
    |> where([c], c.username == ^username)
    |> preload(^preload)
    |> Repo.one!
  end

  def count(query) do
    query |> select([m], count(m.id)) |> Repo.one
  end

  def last_page(query, page_size \\ 75) do
    count = count(query)
    offset = case count - page_size do
      offset when offset >= 0 -> offset
      _ -> 0
    end
    query |> offset(^offset) |> limit(^page_size)
  end

  def user_preload(preload) do
    Hooks.user_preload preload
  end

  @dt_re ~r/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d+)/

  def get_timestamp() do
    get_timestamp(DateTime.utc_now())
  end

  def get_timestamp(dt) do
    @dt_re
    |> Regex.run(dt |> to_string)
    |> tl
    |> to_string
  end

  def format_date(%NaiveDateTime{} = dt) do
    {{yr, mo, day}, _} = NaiveDateTime.to_erl(dt)
    month(mo) <> " " <> to_string(day) <> ", " <> to_string(yr)
  end
  def format_date(%DateTime{} = dt), do: dt |> DateTime.to_naive |> format_date

  def format_time(%NaiveDateTime{} = dt) do
    {_, {hr, min, _sec}} = NaiveDateTime.to_erl(dt)
    min = to_string(min) |> String.pad_leading(2, "0")
    {hr, meridan} =
      case hr do
        hr when hr < 12 -> {hr, ~g" AM"}
        hr when hr == 12 -> {hr, ~g" PM"}
        hr -> {hr - 12, ~g" PM"}
      end
    to_string(hr) <> ":" <> min <> meridan
  end
  def format_time(%DateTime{} = dt), do: dt |> DateTime.to_naive |> format_time

  def format_date_time(%NaiveDateTime{} = dt) do
    format_date(dt) <> " " <> format_time(dt)
  end
  def format_date_time(%DateTime{} = dt), do: dt |> DateTime.to_naive |> format_date_time

  def format_javascript_errors([]), do: %{}
  def format_javascript_errors(errors) do
    errors
    |> Enum.map(fn {k, {msg, opts}} ->
      error = if count = opts[:count] do
        Gettext.dngettext(UcxUccWeb.Gettext, "errors", msg, msg, count, opts)
      else
        Gettext.dgettext(UcxUccWeb.Gettext, "errors", msg, opts)
      end
      {k, error}
    end)
    |> Enum.into(%{})
  end

  def month(1), do: ~g"January"
  def month(2), do: ~g"February"
  def month(3), do: ~g"March"
  def month(4), do: ~g"April"
  def month(5), do: ~g"May"
  def month(6), do: ~g"June"
  def month(7), do: ~g"July"
  def month(8), do: ~g"August"
  def month(9), do: ~g"September"
  def month(10), do: ~g"October"
  def month(11), do: ~g"November"
  def month(12), do: ~g"December"

  def response_message(_channel_id, _body) do
    raise "response_message not supported"
    # body = UccChatWeb.MessageView.render("message_response_body.html", message: message)
    # |> Phoenix.HTML.safe_to_string

    # bot_id = get_bot_id()
    # message = MessageService.create_message(body, bot_id, channel_id,
    #   %{
    #     type: "p",
    #     system: true,
    #     sequential: false,
    #   })

    # html = MessageService.render_message(message)
    # # message =
    # #   message
    # #   |> Enum.filter(&elem(&1, 0) == :text)
    # #   |> Enum.join("")

    # %{html: html, message: message.body}
  end
  def get_bot_id do
    UcxUcc.Accounts.get_bot_id()
  end

  def render(view, templ, opts \\ []) do
    templ
    |> view.render(opts)
    |> safe_to_string
  end

  @doc """
  Convert form submission params form channel into params for changesets.

  ## Examples

        iex> params =  [%{"name" => "_utf8", "value" => "✓"},
        ...> %{"name" => "account[language]", "value" => "en"},
        ...> %{"name" => "account[desktop]", "value" => ""},
        ...> %{"name" => "account[alert]", "value" => "1"}]
        iex> UccChat.ServiceHelpers.normalize_form_params(params)
        %{"_utf8" => "✓", "account" => %{"language" => "en", "alert" => "1"}}
  """
  def normalize_form_params(params) do
    Enum.reduce params, %{}, fn
      %{"name" => _field, "value" => ""}, acc ->
        acc
      %{"name" => field, "value" => value}, acc ->
        parse_name(field)
        |> Enum.reduce(value, fn key, acc -> Map.put(%{}, key, acc) end)
        |> UcxUcc.Utils.deep_merge(acc)
    end
  end

  @doc """
  Convert form parameters returned by Drab into controller type params
  map.

    # Examples

      iex> UccChat.ServiceHelpers.normalize_params %{"_csrf" =>
      ...> "1234", "user[id]" => "42", "user[email]" => "test@test.com",
      ...> "user[account][id]" => "99", "user[account][address][street]" =>
      ...> "123 Any Street"}
      %{"_csrf" => "1234",
      "user" => %{"account" => %{"address" => %{"street" => "123 Any Street"},
      "id" => "99"}, "email" => "test@test.com", "id" => "42"}}
  """
  def normalize_params(params) do
    Enum.reduce(params, "", fn {k, v}, acc ->
      acc <> k <> "=" <> v <> "&"
    end)
    |> String.trim_trailing("&")
    |> Plug.Conn.Query.decode()
  end

  defp parse_name(string), do: parse_name(string, "", [])

  defp parse_name("", "", acc), do: acc
  defp parse_name("", buff, acc), do: [buff|acc]
  defp parse_name("[" <> tail, "", acc), do: parse_name(tail, "", acc)
  defp parse_name("[" <> tail, buff, acc), do: parse_name(tail, "", [buff|acc])
  defp parse_name("]" <> tail, buff, acc), do: parse_name(tail, "", [buff|acc])
  defp parse_name(<<ch::8>> <> tail, buff, acc), do: parse_name(tail, buff <> <<ch::8>>, acc)

  def broadcast_message(body, user_id, channel_id) do
    channel = Channel.get! channel_id
    broadcast_message(body, channel.name, user_id, channel_id)
  end

  def broadcast_message(_body, _room, _user_id, _channel_id, _opts \\ []) do
    raise "broadcast_message not supported"
    # UccChat.TypingAgent.stop_typing(channel_id, user_id)
    # MessageService.update_typing(channel_id, room)
    # {message, html} = MessageService.create_and_render(body, user_id, channel_id, opts)
    # MessageService.broadcast_message(message.id, room, user_id, html)
  end

  def show_sweet_dialog(socket, opts) do
    header = if opts[:confirm], do: opts[:header] || ~g"Are you sure?"
    opts = Map.put(opts, :header, header)

    html = UccChatWeb.MasterView.render("sweet.html", opts: Map.put(opts, :show, true))
    |> safe_to_string
    Phoenix.Channel.push socket, "sweet:open", %{html: html}
  end

  def strip_tags(html) do
    String.replace html, ~r/<.*?>/, ""
  end
  # def hide_sweet_dialog(socket) do

  # end
  def safe_to_string(safe) do
    safe
    |> Phoenix.HTML.safe_to_string
    |> String.replace(~r/\n\s*/, " ")
  end

end
