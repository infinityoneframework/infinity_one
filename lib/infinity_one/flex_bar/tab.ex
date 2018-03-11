defmodule InfinityOne.TabBar.Tab do
  @doc """
  Struct defining a TabBar tab.
  """
  @type t :: %__MODULE__{
    module:    Module.t,
    groups:    List.t,
    id:        String.t,
    title:     String.t,
    icon:      String.t,
    view:      Module.t,
    template:  String.t,
    order:     integer,
    opts:      Keyword.t
  }

  defstruct [
    :module,
    :type,
    :groups,
    :id,
    :title,
    :icon,
    :view,
    :template,
    :order,
    :display,
    :opts]

  def new(module, groups, id, title, icon, view, template, order, opts \\ []) do
    %__MODULE__{
      module:    module,
      type:      :button,
      groups:    groups,
      id:        id,
      title:     title,
      icon:      icon,
      view:      view,
      template:  template,
      order:     order,
      display:   true,
      opts:      opts
    }
  end

  def new(module, id) do
    %__MODULE__{
      module: module,
      type: :hidden,
      id: id,
      display: false,
      opts: []
    }
  end

  def separator(id, groups, order) do
    %__MODULE__{
      id: id,
      type: :separator,
      groups: groups,
      order: order,
      display: true,
      opts: []
    }
  end
end
