defmodule MscsWeb.ClientView do
  use MscsWeb, :view

  @sp "&nbsp;"
  @empty Phoenix.HTML.raw("&nbsp;")
  @dp_alpha [@empty | ~w(abc def ghi jkl mno pqrs tuv wxyz)]

  def get_strips(1) do
    keys = [{"phone-i-idle", "526"}, {"phone-i-idle", "526"}, {"", "553"}, {"", "Timestamp"}]
    for i <- 0..11 do
        case Enum.at keys, i do
          nil           -> {i, "", @sp}
          {"", label}   -> {i, "", label}
          {icon, label} -> {i, icon, label}
        end
    end
  end

  def get_dialpad_keys do
    for {alpha, i} <- Enum.with_index(@dp_alpha) do
      {i + 1, i + 1, alpha}
    end ++ [
      {"*", "star", @empty},
      {0, 0, @empty},
      {"#", "hash", @empty}
    ]
  end
end
