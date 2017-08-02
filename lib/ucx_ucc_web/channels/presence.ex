defmodule UcxUccWeb.Presence do
  use Phoenix.Presence, otp_app: :ucx_ucc,
                        pubsub_server: UcxUccWeb.PubSub

end
