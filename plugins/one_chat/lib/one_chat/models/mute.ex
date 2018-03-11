defmodule OneChat.Mute do
  use OneModel, schema: OneChat.Schema.Mute

  def user_muted?(channel_id, user_id) do
    !!get_by(channel_id: channel_id, user_id: user_id)
  end

end
