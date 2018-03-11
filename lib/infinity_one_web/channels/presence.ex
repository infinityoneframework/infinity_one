defmodule InfinityOneWeb.Presence do
  use Phoenix.Presence, otp_app: :infinity_one,
                        pubsub_server: InfinityOneWeb.PubSub

end
