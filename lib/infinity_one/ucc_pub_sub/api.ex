defmodule InfinityOne.OnePubSub.Api do

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro handle_callback(topic) do
    quote do
      def handle_info({unquote(topic), event, payload,
        {mod, fun}} = msg, %{assigns: %{user_id: user_id}} = socket) do
        if not function_exported?(mod, fun, 3) do
          raise "handle_callback handler undefined for " <> inspect({mod, fun, 3})
        end
        Rebel.cast_fun(socket, fn -> apply(mod, fun, [event, payload, socket]) end)
        {:noreply, socket}
      end
    end
  end

  defmacro subscribe_callback(pid, topic, event, fun) when is_atom(fun) do
    quote do
      InfinityOne.OnePubSub.subscribe unquote(pid), unquote(topic),
        unquote(event), {__MODULE__, unquote(fun)}
    end
  end

  defmacro subscribe_callback(pid, topic, event, mf) when is_tuple(mf) do
    quote do
      InfinityOne.OnePubSub.subscribe unquote(pid), unquote(topic),
        unquote(event), unquote(mf)
    end
  end

  defmacro subscribe_callback(topic, event, fun) do
    quote do
      InfinityOne.OnePubSub.Api.subscribe_callback self(), unquote(topic),
        unquote(event), unquote(fun)
    end
  end

end
