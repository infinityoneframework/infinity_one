defmodule MscsRuntimeError do
  @moduledoc """
  General Application Level Runtime Error.
  """
  defexception message: "Runtime Error"
end

defmodule MscsDataIntegrityError do
  @moduledoc """
  Application level data integrity error.
  """
  defexception message: "DataIntegrity Error"
end
