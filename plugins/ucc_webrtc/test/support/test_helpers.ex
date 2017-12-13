defmodule UccWebrtc.TestHelpers do

  alias UccWebrtc.ClientDevice
  # alias FakerElixir, as: Faker

  use Bitwise

  def insert_client_device(%{username: _} = user) do
    insert_client_device(user, %{})
  end

  def insert_client_device(%{user_id: id} = attrs) when not is_nil(id) do
    changes = Map.merge(%{
      ip_addr: random_ip(),
      handsfree_input_id: uuid(),
      handsfree_output_id: uuid(),
      headset_input_id: uuid(),
      headset_output_id: uuid(),
      video_input_id: uuid(),
    }, to_map(attrs))

    ClientDevice.create! changes
  end

  def insert_client_device(user, attrs) do
    %{user_id: user.id}
    |> Map.merge(to_map(attrs))
    |> insert_client_device()
  end

  defp to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  defp to_map(attrs), do: attrs

  defp random_ip do
    :rand.uniform(255) +
    (:rand.uniform(255) <<< 8) +
    (:rand.uniform(255) <<< 16) +
    (:rand.uniform(255) <<< 24)
  end

  def uuid, do: UUID.uuid1()

end
