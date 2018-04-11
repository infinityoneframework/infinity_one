defmodule OneChatWeb.RoomChannel.Constants do
  defmacro __using__(_) do
    quote do
      @item           ".popup-item"
      @selected       @item <> ".selected"
      @message_box    "textarea.message-form-text"

      @app_pattern_strs   [
                            "^\/([^\s]*)$",
                            "(.)*@([^\s]*)$",
                            "(.)*#([^\s]*)$",
                            "(.)*:([^\s]*)$",
                            # "(.)*ii([^\s]*)$"
                          ]
      @app_patterns       Enum.map(@app_pattern_strs, &Regex.compile!/1)

      @slash_app_pattern  "^\/([^\s]*)$"
      # @other_apps_pattern "(?:.*\s|^)[@#:]|ii([^\s]*)$"
      @other_apps_pattern "(?:.*\s|^)[@#:]([^\s]*)$"
      @match_all_apps     ~r/#{@slash_app_pattern}|#{@other_apps_pattern}/

      @slash_app_pattern1  "^(\/)([^\s]*)$"
      @other_apps_pattern1 ".*([@#:])([^\s]*)$"
      # @other_apps_pattern1 ".*([@#:]|ii)([^\s]*)$"
      @match_all_apps1    ~r/#{@slash_app_pattern1}|#{@other_apps_pattern1}/

      # @all_app_patterns   Regex.compile!(
      #                              Enum.map(
      #                               @app_pattern_strs, & "(" <> &1 <> ")")
      #                              |> Enum.join("|"))

      @slash_key          "/"
      @other_app_keys     ~w(@ # :)
      @app_keys           [@slash_key | @other_app_keys]

      @app_keys_string    Enum.join(@other_app_keys, "")

      @all_app_patterns   ~r/(^#{@slash_key})([^\s]*)$|.*([#{@app_keys_string}])([^\s]*)$/

      @app_mods           [SlashCommands, Users, Channels, Emojis]
      # @app_mods           [SlashCommands, Users, Channels, Emojis, Pages]
      @app_lookup         Enum.zip(@app_keys, @app_mods) |> Enum.into(%{})
      @pattern_key_lookup Enum.zip(@app_keys, @app_patterns) |> Enum.into(%{})
      @pattern_mod_lookup Enum.zip(@app_mods, @app_patterns) |> Enum.into(%{})
      @app_key_lookup     Enum.zip(@app_mods, @app_keys) |> Enum.into(%{})

      @up_arrow           "ArrowUp"
      @dn_arrow           "ArrowDown"
      @left_arrow         "ArrowLeft"
      @right_arrow        "ArrowRight"
      @bs                 "Backspace"
      @tab                "Tab"
      @cr                 "Enter"
      @esc                "Escape"

      @special_keys       [@esc, @up_arrow, @dn_arrow, @left_arrow,
                                  @right_arrow, @bs, @tab, @cr]

      @fn_keys            (for n <- 1..15, do: "F#{n}")

      @ignore_keys        @fn_keys ++ ~w(Shift Meta Control Alt
                                                 PageDown PageUp Home)
    end
  end
end
