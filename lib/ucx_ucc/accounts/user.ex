defmodule UcxUcc.Accounts.User do
  @moduledoc false
  use Coherence.Schema
  use Unbrella.Schema
  import Ecto.Query

  @mod __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "accounts_users" do
    field :name, :string
    field :email, :string
    field :username, :string

    field :avatar_url, :string
    field :tz_offset, :integer
    field :alias, :string
    field :chat_status, :string
    field :tag_line, :string
    field :uri, :string
    field :active, :boolean

    many_to_many :roles, UcxUcc.Accounts.Role, join_through: UcxUcc.Accounts.UserRole
    has_one :account, UcxUcc.Accounts.Account

    coherence_schema()

    timestamps(type: :utc_datetime)
  end

  @all_params ~w(name email username tz_offset alias chat_status tag_line uri active avatar_url)a
  @required  ~w(name email username)a

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @all_params ++ coherence_fields())
    |> validate_required(@required)
    |> validate_exclusion(:username, ["all", "here"])
    |> validate_format(:username, ~r/^[\.a-zA-Z0-9-_]+$/)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> validate_coherence(params)
  end

  def changeset(model, params, :password) do
    model
    |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
    |> validate_coherence_password_reset(params)
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
    user.roles
    |> Enum.reduce([], fn
      %{role: role, scope: ^channel_id}, acc -> [role | acc]
      %{role: "user"}, acc -> acc
      %{role: role}, acc when role in ~w(bot guest admin) -> [role | acc]
      _, acc -> acc
    end)
    |> Enum.map(&String.capitalize/1)
    |> Enum.sort
  end

  def has_role?(user, role, scope \\ nil) do
    Enum.any?(user.roles, fn
      %{role: ^role, scope: ^scope} -> true
      _ -> false
    end)
  end
end
