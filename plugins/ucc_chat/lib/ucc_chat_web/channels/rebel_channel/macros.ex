defmodule UccChatWeb.RebelChannel.Macros do

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      import Rebel.Query, warn: false
      import Rebel.Core, warn: false
      import UccChatWeb.RebelChannel.Client, warn: false
    end
  end

  defmacro defjs(name, do: block) do
    name_js = String.to_atom("#{name}_js")

    quote bind_quoted: [name: name, name_js: name_js, content: block] do

      def unquote(name)(socket) do
        do_exec_js socket, apply(__MODULE__, unquote(name_js), [])
        socket
      end

      def unquote(name_js)() do
        unquote(content)
        |> String.replace("\n", "")
      end
    end
  end

  defmacro defdelegateadmin(name) do
    quote bind_quoted: [name: name] do
      defdelegate unquote(name)(socket, sender), to: UccAdminWeb.AdminChannel
    end
  end

end
