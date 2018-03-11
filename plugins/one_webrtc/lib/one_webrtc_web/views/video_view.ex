defmodule OneWebrtcWeb.VideoView do
  use OneWebrtcWeb, :view
  alias InfinityOne.Coherence.Schemas
  # alias OneChat.Attachment

  def username_by_user_id(id) do
    Schemas.get_user(id) |> Map.get(:username)
  end

  # import InfinityOne.Accounts, only: [username_by_user_id: 1]

end
