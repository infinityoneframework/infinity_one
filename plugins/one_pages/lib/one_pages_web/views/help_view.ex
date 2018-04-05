defmodule OnePagesWeb.HelpView do
  use OnePagesWeb, :view

  def format_slash_commands_table_entries do
    OneChat.SlashCommands.command_list()
    |> Enum.map(fn command ->
      "| **#{command.command}** #{command.args} | _#{command.description}_ |"
    end)
    |> Enum.join("\n")
  end

end
