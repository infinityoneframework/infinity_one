defmodule UcxUccWeb.LandingChannel do
  use UcxUccWeb, :channel

  use Rebel.Channel, name: "landing", controllers: [
    UcxUccWeb.LandingController
  ]
  import Phoenix.HTML.Tag

  alias UcxUccWeb.Query
  alias UcxUcc.Accounts
  alias UccChatWeb.RebelChannel.Client

  require Logger

  onconnect :on_connect

  ############
  # API

  def on_connect(socket) do
    socket
  end

  def topic(_broadcasting, _controller, _request_path, _conn_assigns) do
    "all"
  end

  def join(topic, msg, socket) do
    super topic, msg, socket
  end

  def click_next(socket, sender) do
    step = get_step(socket, sender) |> String.to_integer()

    clear_errors(socket, step)
    if socket = next_step(socket, sender, step) do
      next_link(socket, step)
    else
      socket
    end
  end

  def click_prev(socket, sender) do
    step = get_step(socket, sender) |> String.to_integer()

    socket
    |> prev_link(step)
    |> prev_step(step)
  end

  def click_summary(socket, sender) do
    step = get_step(socket, sender) |> String.to_integer()

    if socket = next_step(socket, sender, step) do
      socket
      |> next_link(step)
      |> render_summary(sender["form"])
    else
      socket
    end
  end

  def menu_click(socket, sender) do
    if String.contains? sender["class"], "disabled" do
      socket
    else
      step = sender["dataset"]["step"] |> String.to_integer
      jump_to_page(socket, step)
    end
  end

  def click_submit(socket, sender) do
    attrs = UccChat.ServiceHelpers.normalize_params(sender["form"])
    case UcxUcc.Landing.create(attrs) do
      {:ok, _} ->
        handle_success(socket, attrs)
      error ->
        error
        |> Tuple.to_list()
        |> tl
        |> Enum.take(2)
        |> handle_submit_errors(socket)
    end
  end

  defp handle_submit_errors([:user, changeset], socket) do
    changeset.errors
    |> get_and_render_errors("admin", socket)
    |> jump_to_page(2)
    |> icon_attention(2)
  end

  defp handle_submit_errors([:channel, changeset], socket) do
    changeset.errors
    |> get_and_render_errors("default_channel", socket)
    |> jump_to_page(3)
    |> icon_attention(3)
  end

  defp handle_submit_errors([_, changeset], socket) do
    Client.toastr socket, :error, UcxUccWeb.Utils.format_errors(changeset)
  end

  defp jump_to_page(socket, step) do
    socket
    |> Query.delete(class: "active", from: ~s/.rooms-list li[data-step]/)
    |> Query.insert(:class, set: "active", on: ~s/.rooms-list li[data-step="#{step}"]/)
    |> Query.delete(class: "open", from: ~s/article[data-step]/)
    |> Query.insert(:class, set: "open", on: ~s/article[data-step="#{step}"]/)
  end

  defp next_link(socket, step) do
    socket
    |> Query.delete(class: "active", from: ~s/.rooms-list li[data-step="#{step}"]/)
    |> Query.delete(class: "disabled", from: ~s/.rooms-list li[data-step="#{step + 1}"]/)
    |> Query.insert(:class, set: "active", on: ~s/.rooms-list li[data-step="#{step + 1}"]/)
  end

  defp next_step(socket, sender, step) do
    if validate(step, socket, sender) do
      socket
      |> Query.delete(class: "open", from: ~s/article[data-step="#{step}"]/)
      |> Query.insert(:class, set: "open", on: ~s/article[data-step="#{step + 1}"]/)
      |> icon_ok(step)
    else
      icon_attention(socket, step)
      false
    end
  end

  defp prev_link(socket, step) do
    socket
    |> Query.delete(class: "active", from: ~s/.rooms-list li[data-step="#{step}"]/)
    |> Query.insert(:class, set: "active", on: ~s/.rooms-list li[data-step="#{step - 1}"]/)
  end

  defp prev_step(socket, step) do
    socket
    |> Query.delete(class: "open", from: ~s/article[data-step="#{step}"]/)
    |> Query.insert(:class, set: "open", on: ~s/article[data-step="#{step - 1}"]/)
  end

  defp get_step(socket, sender) do
    exec_js! socket, "$('#{this(sender)}').closest('article').attr('data-step')"
  end

  defp validate(1, socket, sender) do
    sender["form"]["host_name"]
    |> String.match?(~r/^[\w\.]+$/)
    |> case do
      true ->
        true
      _    ->
        render_error(socket, "#host_name",
          ~g(can only contain word alphanumeric, _, and . characters))
        false
    end
  end

  defp validate(2, socket, sender) do
    attrs = UccChat.ServiceHelpers.normalize_params(sender["form"])["admin"]
    case Accounts.change_user(attrs) do
      %{valid?: true} ->
        true
      %{errors: errors} ->
        get_and_render_errors(errors, "admin", socket)
        false
    end
  end

  defp validate(3, socket, sender) do
    attrs = UccChat.ServiceHelpers.normalize_params(sender["form"])["default_channel"]

    case UccChat.Channel.change(Map.put(attrs, "user_id", Ecto.UUID.generate)) do
      %{valid?: true} ->
        true
      %{errors: errors} ->
        get_and_render_errors(errors, "default_channel", socket)
        false
    end
  end

  defp validate(4, socket, sender) do
    attrs = UccChat.ServiceHelpers.normalize_params(sender["form"])["email_from"]
    errors =
      if String.length(attrs["name"]) < 3 do
        [name: {~g"must be more than 2 characters long", []}]
      else
        []
      end
    if String.match?(attrs["email"], ~r/@/) do
      errors
    else
      [{:email, {~g(invalid fomat), []}} | errors]
    end
    |> case do
      [] ->
        true
      errors ->
        get_and_render_errors(errors, "email_from", socket)
        false
    end
  end

  defp validate(_, _socket, _sender), do: true

  defp icon_ok(socket, step) do
    async_js socket, ~s/$('.rooms-list li[data-step="#{step}"] a > i').attr('class', 'icon icon-ok')/
    socket
  end
  defp icon_attention(socket, step) do
    async_js socket, ~s/$('.rooms-list li[data-step="#{step}"] a > i').attr('class', 'icon icon-attention')/
    socket
  end

  defp get_and_render_errors(errors, prefix, socket) do
    errors
    |> Enum.map(fn {field, {error, _}} ->
      {"##{prefix}_#{field}", error}
    end)
    |> render_errors(socket)
  end

  def render_summary(socket, form) do
    fields = UccChat.ServiceHelpers.normalize_params(form)
    html =
      UcxUccWeb.LandingView
      |> Phoenix.View.render_to_string("summary.html", results: fields)
      |> Poison.encode!

    async_js socket, ~s/$('.landing-summary').html(#{html});/
  end

  defp render_error(socket, id, message) do
    async_js socket, message |> error_tag() |> error_js(id)
  end

  defp render_errors(errors, socket) do
    js =
      errors
      |> Enum.map(fn {id, message} ->
        message
        |> error_tag
        |> error_js(id)
      end)
      |> Enum.join("")
    async_js socket, js
  end

  defp error_js(message, id),
    do: ~s/$('#{id}').addClass('error').parent().append(#{message});/

  defp error_tag(message) do
    content_tag :span, [class: "error"] do
      message
    end
    |> Phoenix.HTML.safe_to_string
    |> Poison.encode!()
  end

  def clear_error(socket, id) do
    async_js socket, """
      $('#{id}').removeClass('error');
      $('#{id} ~ span.error').remove();
      """ |> String.replace("\n", "")
  end

  def clear_errors(socket, step) do
    async_js socket, """
      $('article[data-step="#{step}"] span.error').remove();
      $('article[data-step="#{step}"] .error').removeClass('error');
      """
  end

  defp handle_success(socket, attrs) do
    html =
      UcxUccWeb.LandingView
      |> Phoenix.View.render_to_string("success.html",
        username: attrs["admin"]["username"], channel_name: attrs["default_channel"]["name"])
      |> Poison.encode!

    socket
    |> async_js(~s/$('.wrapper > .main-content > .content').html(#{html});/)
    |> async_js(~s/$('.rooms-list li[data-step]').addClass('disabled')/)
    |> async_js(~s/$('.rooms-list li[data-step="5"]').removeClass('active')/)
    |> async_js(~s/$('.rooms-list li[data-step="6"]').addClass('active')/)
    |> icon_ok(5)
    |> async_js(~s/$('.rooms-list li[data-step="6"] a > i').attr('class', 'icon icon-award')/)
  end
end
