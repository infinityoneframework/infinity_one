defmodule InfinityOne.Accounts.User do
  @moduledoc false

  use Coherence.Schema
  use Unbrella.Schema
  use Arc.Ecto.Schema
  import Ecto.Query

  alias InfinityOne.OnePubSub
  alias InfinityOne.Accounts

  require Logger

  @mod __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :name, :string
    field :email, :string
    field :username, :string

    field :avatar, OneChat.Avatar.Type
    field :avatar_url, :string
    field :tz_offset, :integer
    field :alias, :string
    field :tag_line, :string
    field :uri, :string
    field :active, :boolean
    field :delete_avatar, :boolean, default: false, virtual: true
    field :join_default_channels, :boolean, virtual: true
    field :send_welcome_email, :boolean, virtual: true
    field :confirm_account, :boolean, virtual: true
    field :role, :string, virtual: true

    has_many :user_roles, InfinityOne.Accounts.UserRole
    has_many :roles, through: [:user_roles, :role]
    has_many :phone_numbers, InfinityOne.Accounts.PhoneNumber, on_replace: :delete
    has_one :account, InfinityOne.Accounts.Account

    coherence_schema()

    timestamps(type: :utc_datetime)
  end

  @all_params ~w(name email username tz_offset alias tag_line uri active
                 avatar_url delete_avatar join_default_channels
                 send_welcome_email confirm_account role)a
  @required  ~w(name email username)a

  def changeset(model, params \\ %{}) do
    # TODO: Not sure how to do this elegantly, but this hack works for removing
    #       existing phone numbers

    params =
      if params["phone_numbers"] == [""] do
        Map.put(params, "phone_numbers", [])
      else
        params
      end

    params =
      case {model, Map.keys(params)} do
        {%{id: id}, _} when not is_nil(id) -> params
        {_, [key | _]} when is_atom(key) ->
          Map.put(params, :account, params[:account] || %{})
        _ ->
          Map.put(params, "account", params["account"] || %{})
      end

    model
    |> cast(params, @all_params ++ coherence_fields())
    |> validate_required(@required)
    |> cast_attachments(params, [:avatar])
    |> cast_assoc(:phone_numbers)
    |> cast_assoc(:account)
    |> validate_exclusion(:username, ["all", "here"])
    |> validate_format(:username, ~r/^[\.a-zA-Z0-9-_]+$/)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_coherence(params)
    |> plugin_changesets(params, __MODULE__)
    |> prepare_changes(&prepare_confirmation/1)
    |> prepare_changes(&perpare_welcome_email/1)
    |> prepare_changes(&prepare_avatar/1)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
  end

  def perpare_welcome_email(%{valid?: true, action: :insert, changes: %{send_welcome_email: true}} = changeset) do
    url = InfinityOneWeb.Router.Helpers.url InfinityOneWeb.Endpoint
    Coherence.Controller.send_user_email(:welcome, changeset.changes, url)
    changeset
  end

  def perpare_welcome_email(changeset) do
    changeset
  end

  def prepare_avatar(%{valid?: true, changes: %{delete_avatar: true}} = changeset) do
    path = OneChat.Avatar.storage_dir(changeset.data)
    File.rm_rf path

    notify_user_avatar_change(changeset.data.id)
    put_change(changeset, :avatar, nil)
  end

  def prepare_avatar(%{valid?: true, changes: %{avatar: _ = %{}}} = changeset) do
    notify_user_avatar_change(changeset.data.id)
    changeset
  end

  def prepare_avatar(changeset) do
    changeset
  end

  def prepare_confirmation(%{action: action} = changeset) when action != :insert do
    changeset
  end

  def prepare_confirmation(%{valid?: true, changes: %{confirm_account: false}} = changeset) do
    if InfinityOne.Settings.Accounts.require_account_confirmation do
      InfinityOneWeb.Coherence.InvitationController.send_confirmation(changeset)
    else
      changeset
      |> put_change(:confirm_account, true)
      |> prepare_confirmation()
    end
  end

  def prepare_confirmation(%{valid?: true, changes: %{confirm_account: true}} = changeset) do
    changeset
    |> put_change(:confirmed_at, Ecto.DateTime.utc)
    |> put_change(:confirmation_token, nil)
  end

  def prepare_confirmation(%{valid?: true} = changeset) do
    if InfinityOne.Settings.Accounts.require_account_confirmation do
      changeset
    else
      changeset
      |> put_change(:confirm_account, true)
      |> prepare_confirmation()
    end
  end
  def prepare_confirmation(changeset) do
    changeset
  end

  defp notify_user_avatar_change(user_id) do
    spawn fn ->
      Process.sleep 750
      user = Accounts.get_user(user_id)
      url = OneChatWeb.SharedView.avatar_url(user)
      OnePubSub.broadcast "user:all", "avatar:change", %{
        user: user,
        user_id: user_id,
        username: user.username,
        url: url
      }
    end
  end

  def total_count do
    from u in @mod, select: count(u.id)
  end

  def user_id_and_username(user_id) do
    from u in @mod,
      where: u.id == ^user_id,
      select: {u.id, u.username}
  end
  def user_from_username(username) do
    from u in @mod,
      where: u.username == ^username
  end

  def display_name(%@mod{} = user) do
    user.alias || user.username
  end

  def all do
    from u in @mod
  end

  def tags(user, channel_id) do
    user.user_roles
    |> Enum.reduce([], fn
      %{role: %{name: role}, scope: ^channel_id}, acc -> [role | acc]
      %{role: %{name: "user"}}, acc -> acc
      %{role: %{name: role}}, acc when role in ~w(bot guest admin) -> [role | acc]
      _, acc -> acc
    end)
    |> Enum.map(&String.capitalize/1)
    |> Enum.sort
  end
end
