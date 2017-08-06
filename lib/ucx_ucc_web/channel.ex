defmodule UcxUccWeb.Channel do
  @moduledoc """
  Channel helpers
  """

  @type socket :: Phoenix.Socket.t

  @doc """
  Return the :noreply tuple
  """
  @spec noreply(socket) :: {:noreply, socket}
  def noreply(socket), do: {:noreply, socket}

  @doc """
  Return the reply tuple
  """
  @spec reply(any, socket) :: {:reply, any, socket}
  def reply(reply, socket), do: {:reply, reply, socket}

end
