defmodule UcxUcc.Landing do
  @doc """
  Context for creating the database entires from the landing channel.

  """

  alias Ecto.Multi
  alias UcxUcc.{Accounts, Repo}
  alias UccChat.Channel
  alias UcxUcc.Settings.General

  def create(attrs) do
    Multi.new()
    |> Multi.run(:user, &do_insert_user(&1, attrs))
    |> Multi.run(:add_role, &add_user_role/1)
    |> Multi.run(:confirm_user, &confirm_user(&1, attrs))
    |> Multi.run(:channel, &do_insert_channel(&1, attrs))
    |> Multi.run(:subscription, &subscribe_channel/1)
    |> Multi.run(:update_host, &update_host(&1, attrs))
    |> Multi.run(:update_email_from, &update_email_from(&1, attrs))
    |> Multi.run(:run_hooks, &run_hooks(&1, attrs))
    |> Repo.transaction
  end

  defp do_insert_user(_changes, attrs) do
    Accounts.create_user(attrs["admin"])
  end

  defp add_user_role(%{user: user}) do
    Accounts.add_role_to_user(user, "admin")
  end

  defp do_insert_channel(%{user: user}, attrs) do
    attrs["default_channel"]
    |> Map.put("user_id", user.id)
    |> Map.put("default", true)
    |> Channel.create()
  end

  defp subscribe_channel(%{user: user, channel: channel}) do
    UccChat.Subscription.create(%{channel_id: channel.id, user_id: user.id})
  end

  defp confirm_user(%{user: user}, _attrs) do
    Coherence.Controller.confirm! user
  end

  defp update_host(_changes, attrs) do
    host_name = attrs["host_name"]

    # Update the current environment
    endpoint =
      :ucx_ucc
      |> Application.get_env(UcxUccWeb.Endpoint)
      |> put_in([:url, :host], host_name)

    Application.put_env :ucx_ucc, UcxUccWeb.Endpoint, endpoint

    General.update General.get, %{site_url: host_name}

    {:ok, host_name}
  end

  defp update_email_from(_changes, attrs) do
    email_from = attrs["email_from"]
    Application.put_env :coherence, :email_from_name, email_from["name"]
    Application.put_env :coherence, :email_from_email, email_from["email"]
    {:ok, email_from}
  end

  defp run_hooks(_changes, attrs) do
    {:ok, UcxUcc.Hooks.landing_update(attrs)}
  end
end

