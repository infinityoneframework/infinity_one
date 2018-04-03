defmodule OneAdminWeb.View.Utils do
  import InfinityOneWeb.Gettext
  import Phoenix.HTML.{Tag, Form}, warn: false

  def collapsable_section(title, fun) do
    content_tag :div, class: "section section-collapsed" do
      [
        content_tag :div, class: "section-title" do
          [
            content_tag :div, class: "section-title-text" do
              title
            end,
            content_tag :div, class: "section-title-right" do
              content_tag :button, class: "button primary expand" do
                content_tag :span do
                  ~g"Expand"
                end
              end
            end
          ]
        end,
        content_tag :div, class: "section-content border-component-color" do
          fun.(nil)
        end
      ]
    end
  end

  def reset_section_settings do
    content_tag :div, class: "input-line double-col" do
      [
        content_tag :label, class: "setting-label" do
          ~g"Reset section settings"
        end,
        content_tag :div, class: "setting-field" do
          content_tag :button, class: "reset-group button danger", "rebel-click": :admin_reset_settings_click do
            ~g"Reset"
          end
        end
      ]
    end
  end

  def text_input_line(f, item, field, title, opts \\ []) do
    type = opts[:type] || :text
    description = opts[:description]

    content_tag :div, class: "input-line double-col" do
      [
        content_tag :label, class: "setting-label" do
          title
        end,
        content_tag :div, class: "setting-field" do
          f
          |> text_input(field, class: "input-monitor", type: type)
          |> do_description(description)
        end,
        add_changed(opts, item, field)
      ]
    end
  end


  def add_changed(opts, item, field) do
    module = item.__struct__ |> Module.split() |> List.last() |> Inflex.Underscore.underscore()
    changed = opts[:changed]
    if changed[field] do
      content_tag :button, class: "reset-settings button danger", text: "Reset",
        "data-setting": "#{module}__#{field}", "rebel-click": :admin_reset_setting_click do

        content_tag :i, [class: "icon-ccw secondary-font-color color-error-contrast"], do: ""
      end
    else
      []
    end
  end

  def changed_bindings(module, current) do
    defaults = apply(module, :new, [])
    schema = apply(module, :schema, [])

    changed =
      Enum.reduce(schema.__schema__(:fields), %{}, fn field, acc ->
        if Map.get(defaults, field) != Map.get(current, field) do
          Map.put(acc, field, true)
        else
          acc
        end
      end)
    [defaults: defaults, changed: changed]
  end

  def textarea_input_line(f, item, field, title, opts \\ []) do
    type = opts[:type] || :text
    description = opts[:description]

    content_tag :div, class: "input-line double-col" do
      [
        content_tag :label, class: "setting-label" do
          title
        end,
        content_tag :div, class: "setting-field" do
          f
          |> textarea(field, class: "input-monitor", type: type)
          |> do_description(description)
        end,
        add_changed(opts, item, field)
      ]
    end
  end

  defp do_description(tag, nil), do: tag
  defp do_description(tag, description) when is_list(tag) do
    tag ++ [
      content_tag :div, class: "settings-description" do
        Phoenix.HTML.raw description
      end
    ]
  end
  defp do_description(tag, description) do
    [
      tag,
      content_tag :div, class: "settings-description" do
        Phoenix.HTML.raw description
      end
    ]
  end

  def radio_button_line(f, item, field, title, opts \\ []) do
    checked = Map.get(item, field)
    description = opts[:description]
    content_tag :div, class: "input-line double-col" do
      [
        content_tag :label, class: "setting-label" do
          title
        end,
        content_tag :div, class: "setting-field" do
          [
            content_tag :label do
              [
                radio_button(f, field, "1", checked: checked, class: "input-monitor"),
                "True"
              ]
            end,
            content_tag :label do
              [
                radio_button(f, field, "0", checked: !checked, class: "input-monitor"),
                "False"
              ]
            end
          ]
          |> do_description(description)
        end,
        add_changed(opts, item, field)
      ]
    end
  end

  def select_line(f, item, field, options, title, opts \\ []) do
    description = opts[:description]
    content_tag :div, class: "input-line double-col" do
      [
        content_tag :label, class: "setting-label" do
          title
        end,
        content_tag :div, class: "setting-field" do
          [
            content_tag :div, class: "select-arrow" do
              content_tag :i, class: "icon-down-open secondary-font-color" do
              end
            end,
            select(f, field, options)
          ]
          |> do_description(description)
        end,
        add_changed(opts, item, field)
      ]
    end
  end

  def get_admin_flex_tabs(mode) do
    OneAdmin.FlexAdminService.default_settings(mode)
  end

end
