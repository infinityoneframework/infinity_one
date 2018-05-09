defmodule InfinityOne.TestHelpers do
  alias FakerElixir, as: Faker
  alias InfinityOne.{Repo, Accounts}
  alias Accounts.{User, Role, UserRole}
  import Ecto.Query

  def strip_ts(schema) do
    struct schema, inserted_at: nil, updated_at: nil
  end

  def schema_eq(schema1, schema2) do
    strip_ts(schema1) == strip_ts(schema2)
  end

  def insert_roles do
    [admin: :global, moderator: :rooms, owner: :rooms, user: :global, bot: :global, guest: :global]
    |> Enum.map(fn {role, scope} ->
      Accounts.create_role %{name: to_string(role), scope: to_string(scope)}
    end)
  end

  def insert_roles(roles) do
    Enum.map(roles, fn role ->
      insert_role role
    end)
  end

  def insert_role(name, attrs \\ %{}) do
    changes = Map.merge(%{
      name: name,
      description: name
      }, to_map(attrs))
    Repo.insert! Role.changeset(%Role{}, changes)
  end

  def insert_user(attrs \\ %{})
  def insert_user(attrs) do
    attrs = Enum.into attrs, %{}
    role =
      case attrs[:role] || Repo.one(from r in Role, where: r.name == "user") do
        %Role{} = role ->
          role
        _ ->
          insert_role("user")
      end

    attrs = Map.delete attrs, :role

    changes = Map.merge(%{
      name: Faker.Name.name,
      username: Faker.Internet.user_name,
      email: Faker.Internet.email,
      password: "secret",
      password_confirmation: "secret",
      }, to_map(attrs))

    user =
      %User{}
      |> User.changeset(changes)
      |> Repo.insert!()

    %UserRole{}
    |> UserRole.changeset(%{user_id: user.id, role_id: role.id})
    |> Repo.insert!

    Repo.preload(user, [:account, :roles, user_roles: :role])
  end

  def insert_account(user, attrs \\ %{}) do
    attrs = Enum.into attrs, %{}
    changes = Map.merge(%{
      user_id: user.id
      }, to_map(attrs))

    {:ok, account} = Accounts.create_account changes
    Repo.preload account, [:user]
  end

  def insert_role_user(role, attrs \\ %{}) do
    Map.merge(%{
      role: insert_role(role),
    }, Enum.into(attrs, %{}))
    |> insert_user
  end

  defp to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp to_map(attrs), do: attrs

  def assert_schema(schema) do
    struct(schema, inserted_at: nil, updated_at: nil)
  end
end
