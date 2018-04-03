defmodule OneChatWeb.Admin.Page.ChatGeneral do
  @doc """
  FlexTab panel implementation for ChatGeneral Administration page.
  """
  use OneAdmin.Page

  alias InfinityOne.{Repo, Hooks}
  alias OneChat.Settings.ChatGeneral
  alias OneAdminWeb.View.Utils

  @doc """
  Callback to add the ChatGeneral page into the administration pages.
  """
  def add_page do
    new(
      "admin_chat_general",
      __MODULE__,
      ~g(Chat General),
      OneChatWeb.AdminView,
      "chat_general.html",
      65,
      pre_render_check: &check_perissions/2,
      permission: "view-general-administration"
    )
  end

  @doc """
  Callback to provide the ChatGeneral page rendering bindings.
  """
  def args(page, user, _sender, socket) do
    general = ChatGeneral.get()
    {[
      user: Repo.preload(user, Hooks.user_preload([])),
      changeset: general |> ChatGeneral.changeset(),
    ] ++ Utils.changed_bindings(ChatGeneral, general), user, page, socket}
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

  def check_perissions(_page, user) do
    has_permission? user, "view-general-administration"
  end
end
