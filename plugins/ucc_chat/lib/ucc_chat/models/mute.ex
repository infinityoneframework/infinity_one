defmodule UccChat.Mute do
  use UccModel, schema: UccChat.Schema.Mute

  def user_muted?(channel_id, user_id) do
    !!get_by(channel_id: channel_id, user_id: user_id)
  end

end
