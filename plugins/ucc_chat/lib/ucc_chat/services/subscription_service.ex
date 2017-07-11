defmodule UccChat.SubscriptionService do
  use UccChat.Shared, :service

  alias UccChat.{Subscription}

  def update(%{channel_id: channel_id, user_id: user_id}, params),
    do: __MODULE__.update(channel_id, user_id, params)

  def update(channel_id, user_id, params) do
    case get(channel_id, user_id) do
      nil ->
        {:error, :not_found}
      sub ->
        Subscription.update(sub, params)
    end
  end

  def get(channel_id, user_id) do
    Subscription.get(channel_id: channel_id, user_id: user_id)
  end

  def get(channel_id, user_id, field) do
    case Subscription.get(channel_id: channel_id, user_id: user_id) do
      nil ->
        :error
      sub ->
        Map.get sub, field
    end
  end
end
