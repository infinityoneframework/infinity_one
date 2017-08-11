defmodule UcxUcc.TabBar.Tab do
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
    order:     integer
  }

  defstruct [:module, :type, :groups, :id, :title, :icon, :view, :template, :order, :display]

  def new(module, groups, id, title, icon, view, template, order) do
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
      display:   true
    }
  end

  def new(module, id) do
    %__MODULE__{
      module: module,
      type: :hidden,
      id: id,
      display: false
    }
  end

  def separator(id, groups, order) do
    %__MODULE__{
      id: id,
      type: :separator,
      groups: groups,
      order: order,
      display: true
    }
  end

end
