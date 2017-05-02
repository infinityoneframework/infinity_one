defmodule UcxUcc.TestHelpers do
  alias FakerElixir, as: Faker
  alias UcxUcc.{Repo, Accounts}
  alias Accounts.{User, Role, UserRole}
  import Ecto.Query

  def strip_ts(schema) do
    struct schema, inserted_at: nil, updated_at: nil
  end

  def schema_eq(schema1, schema2) do
    strip_ts(schema1) == strip_ts(schema2)
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
    role = Repo.one!(from r in Role, where: r.name == "user")
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
    Repo.preload user, [roles: :permissions]
  end

  defp to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp to_map(attrs), do: attrs
end
