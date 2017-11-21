defmodule UcxAdapter.Dialer do

  alias ExAmi.Client.Originate

  require Logger

  def dial(_user, user_exten, number, _opts) do
    channel = "UCX/#{user_exten}"
    # Logger.warn "dial channel: #{channel}, number: #{number}"
    Originate.dial :asterisk, channel, {"from-internal", number, "1"},
      [], &response_callback/2
  end


  def response_callback(_response, _events) do
  end

end
