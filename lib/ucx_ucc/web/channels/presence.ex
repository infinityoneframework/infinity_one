defmodule UcxUcc.Web.Presence do
  use Phoenix.Presence, otp_app: :ucx_ucc,
                        pubsub_server: UcxUcc.PubSub

end