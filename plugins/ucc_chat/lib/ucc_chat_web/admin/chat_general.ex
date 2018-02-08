defmodule UccChatWeb.Admin.Page.ChatGeneral do
  @doc """
  FlexTab panel implementation for ChatGeneral Administration page.
  """
  use UccAdmin.Page

  alias UcxUcc.{Repo, Hooks}
  alias UccChat.Settings.ChatGeneral

  @doc """
  Callback to add the ChatGeneral page into the administration pages.
  """
  def add_page do
    new(
      "admin_chat_general",
      __MODULE__,
      ~g(Chat General),
      UccChatWeb.AdminView,
      "chat_general.html",
      65,
      [pre_render_check: &UccChatWeb.Admin.view_message_admin_permission?/2]
    )
  end

  @doc """
  Callback to provide the ChatGeneral page rendering bindings.
  """
  def args(page, user, _sender, socket) do
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: ChatGeneral.get |> ChatGeneral.changeset,
    ], user, page, socket}
  end

  @doc """
  Helper functions to provide HTML select control options for rendering
  the page.
  """
  def options(:notifications), do: [
    {~g(All messages), "all"},
    {~g(Mentions), "mentions"},
    {~g(Nothing), "none"}
  ]

  def options(:unread_count), do: [
    {~g(All messages), "all"},
    {~g(User mentions only), "user"},
    {~g(Group mentions only), "group"},
    {~g(User and group mentions only), "user_and_group"}
  ]

  def options(:unread_count_dm), do: [
    {~g(All messages), "all"},
    {~g(Mentions only), "mentions_only"}
  ]

  def lookup_option(which, field) do
    which
    |> options()
    |> Enum.find(fn {_, fd} -> fd == field end)
    |> elem(0)
  end

end
