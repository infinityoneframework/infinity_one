defmodule UccChatWeb.Channel.Utils do

  defmacro __using__(_) do
    quote do
      alias unquote(__MODULE__)
    end
  end

  def noreply(socket), do: {:noreply, socket}

  defmacro dataset(key, value) do
    quote do
      %{"dataset" => %{unquote(key) => unquote(value)}}
    end
  end
end
