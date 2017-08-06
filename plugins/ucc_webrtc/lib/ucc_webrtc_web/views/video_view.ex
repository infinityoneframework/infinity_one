defmodule UccWebrtcWeb.VideoView do
  use UccWebrtcWeb, :view
  alias UcxUcc.Coherence.Schemas
  # alias UccChat.Attachment

  def username_by_user_id(id) do
    Schemas.get_user(id) |> Map.get(:username)
  end



  # import UcxUcc.Accounts, only: [username_by_user_id: 1]

end
