defmodule UccChat.AvatarService do
  use UccChat.Shared, :service

  @background_colors ~w(F44336 E91E63 9C27B0 673AB7 3F51B5 2196F3 03A9F4 00BCD4 009688 4CAF50 8BC34A CDDC39 FFC107 FF9800 FF5722 795548 9E9E9E 607D8B)
  # @background_count length(@background_colors)

  def avatar_initials(username) do
    initials = get_initials(username)

    background = get_color(username)

"""
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" pointer-events="none" width="50" height="50" style="width: inherit; height: inherit; background-color: ##{background};">
  <text text-anchor="middle" y="50%" x="50%" dy="0.36em" pointer-events="auto" fill="#ffffff" font-family="Helvetica, Arial, Lucida Grande, sans-serif" style="font-weight: 400; font-size: 22px;">
    #{initials}
  </text>
</svg>
"""
  end

  def get_initials(username) do
    {a, b} = if String.contains? username, "." do
      case String.split(username, ".") do
        [<<ch1::8, _::bitstring>>, <<ch2::8, _::bitstring>>|_] -> {<<ch1::8>>, <<ch2::8>>}
        [<<ch1::8, ch2::8, _::bitstring>>|_] -> {<<ch1::8>>, <<ch2::8>>}
      end
    else
      <<ch1::8, ch2::8, _::bitstring>> = username
      {<<ch1::8>>, <<ch2::8>>}
    end
    String.upcase(a) <> String.upcase(b)
  end

  def get_color(_username) do
    # use Bitwise
    # ch = case username do
    #   <<_::8, ch::8, _::bitstring>> -> ch
    #   <<ch::8, _::bitstring>> -> ch
    #   _ -> ?a
    # end

    # len = String.length(username) ^^^ (ch &&& 0x53)

    # inx = rem(len, @background_count)

    # Enum.at(@background_colors, inx)
    Enum.random @background_colors
  end

  def avatar_url(username) do
    "/avatar/#{get_initials(username)}.svg"
  end

  # Can be run from iex to generate a list of files.
  def gen_avatars do
    list = for ch <- ?a..?z, do: <<ch::8>>
    list = for ch1 <- list, ch2 <- list, do: ch1 <> ch2
    for name <- list do
      File.write "assets/static/avatar/#{name}.svg",
        UccChat.Web.AvatarView.render("show.xml",
          color: get_color(name), initials: get_initials(name))
    end
  end
end
