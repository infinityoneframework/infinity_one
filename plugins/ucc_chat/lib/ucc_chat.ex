defmodule UccChat do

  def phone_status? do
    !! Application.get_env :ucx_presence, :enabled
  end

end
