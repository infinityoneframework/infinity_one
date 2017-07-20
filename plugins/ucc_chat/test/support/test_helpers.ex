defmodule UccChat.TestHelpers do
  alias FakerElixir, as: Faker
  # alias UcxUcc.{Repo, Accounts}
  # alias Accounts.{User, Role, UserRole}
  alias UccChat.{ChannelService, Subscription}
  alias UcxUcc.{Accounts, Repo}
  alias UcxUcc.TestHelpers
  alias UccChat.{Notification, AccountNotification}

  # import Ecto.Query

  # def strip_ts(schema) do
  #   struct schema, inserted_at: nil, updated_at: nil
  # end

  # def schema_eq(schema1, schema2) do
  #   strip_ts(schema1) == strip_ts(schema2)
  # end

  defdelegate insert_user(attrs), to: TestHelpers
  defdelegate insert_user(), to: TestHelpers
  defdelegate insert_role(name, attrs), to: TestHelpers
  defdelegate insert_roles(), to: TestHelpers
  defdelegate insert_roles(roles), to: TestHelpers
  defdelegate insert_role_user(role, attrs), to: TestHelpers
  defdelegate strip_ts(schema), to: TestHelpers
  defdelegate schema_eq(schema1, schema2), to: TestHelpers

  def insert_channel(user, attrs \\ %{}) do
    changes =
      Map.merge(%{
        name: Faker.Internet.user_name,
        user_id: user.id
      }, to_map(attrs))
    ChannelService.insert_channel! changes
  end

  def insert_subscription(user, channel, attrs \\ %{}) do
    changes =
      Map.merge(%{
        channel_id: channel.id,
        user_id: user.id
      }, to_map(attrs))
    Subscription.create! changes
  end

  def insert_account(user, attrs \\ %{}) do
    user
    |> UcxUcc.TestHelpers.insert_account(attrs)
    |> Repo.preload([:user, :notifications])
  end

  def insert_notification(channel, attrs \\ %{}) do
    changes =
      Map.merge(%{
        channel_id: channel.id,
        settings: %{},
      }, to_map(attrs))
    Notification.create!(changes)
  end

  def insert_account_notification(account, notification, attrs \\ %{}) do
    changes =
      Map.merge(%{
        account_id: account.id,
        notification_id: notification.id,
      }, to_map(attrs))
    AccountNotification.create!(changes)
  end

  defp to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp to_map(attrs), do: attrs
end
