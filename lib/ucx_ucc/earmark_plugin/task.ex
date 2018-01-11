defmodule UcxUcc.EarmarkPlugin.Task do
  def as_html(lines) do
    case render(lines) do
      {[line], []} -> line
      {lines, []} -> lines
      tuple -> tuple
    end
  end

  defp render(lines) do
    Enum.map(lines, &render_line/1) |> Enum.partition(&ok?/1)
  end

  defp render_line({"[ ] " <> line, _}) do
    "<i class='icon-check-empty'></i> #{line}"
  end
  defp render_line({"[x] " <> line, _}) do
    "<i class='icon-check'></i> #{line}"
  end
  defp render_line({line, lnb}), do: {:error, lnb, line}

  defp ok?({_, _, _}), do: false
  defp ok?(_), do: true

end
