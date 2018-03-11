defmodule InfinityOneWeb.Coherence.SessionView do
  use InfinityOneWeb.Coherence, :view


  def render("create.json", opts) do
    # json conn, %{status: "success", data: Enum.into(opts, %{})}
    opts
  end

  # def render(conn, "success.json", opts \\ []) do
  #   json conn, %{status: "success", data: Enum.into(opts, %{})}
  # end
end
