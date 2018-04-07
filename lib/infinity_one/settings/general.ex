defmodule InfinityOne.Settings.General do
  @moduledoc """
  The General Settings context module.

  Provides access to the General Settings schema.
  """
  use OneSettings.Settings, schema: InfinityOne.Settings.Schema.General

  alias InfinityOne.SiteAvatar
  alias OneChatWeb.SharedView

  @doc """
  The the site_avatar path from the schema and return the url.

  Get the url and trim leading `/priv/static`. Return the internal formated
  url by default. If the `external: true` option is passed, prefixes the url
  with the sites url schema, hostname, and port number.
  """
  def site_avatar_url(general \\ nil, opts \\ [])

  def site_avatar_url(nil, opts) do
    site_avatar_url(__MODULE__.get(), opts)
  end

  def site_avatar_url(opts, _) when is_list(opts) do
    site_avatar_url(__MODULE__.get(), opts)
  end

  def site_avatar_url(%{site_avatar: site_avatar}, opts) do
    site_avatar
    |> SiteAvatar.url()
    |> SharedView.view_url()
    |> add_external(opts[:external])
  end

  def add_external(url, true), do: InfinityOneWeb.root_url() <> url

  def add_external(url, _), do: url

  def get_site_client_name do
    get_site_client_name(__MODULE__.get())
  end

  def get_site_client_name(%{site_client_name: "use-host-name"}) do
    InfinityOneWeb.root_url()
  end

  def get_site_client_name(%{site_client_name: name}) do
    name
  end
end

