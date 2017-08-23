defmodule UccAdmin.Page do
  defmacro __using__(_) do
    quote location: :keep do
      import unquote(__MODULE__)
      import UcxUccWeb.Gettext
      import Rebel.Core, warn: false
      import Rebel.Query, warn: false

      alias UccAdminWeb.AdminChannel
      alias UccChatWeb.RebelChannel.SideNav

      require Logger

      def open(socket, sender, page) do
        user = get_user! socket
        page
        |> args(user, sender, socket)
        |> render_to_string
      end

      def args(page, user, sender, socket) do
        {[user: user], user, page, socket}
      end

      def render_to_string({bindings, user, page, socket}) do
        html = Phoenix.View.render_to_string page.view, page.template, bindings
        admin_flex = AdminChannel.render_to_string("admin_flex.html", user: user)
        socket
        |> update(:html, set: html, on: ".main-content")
        |> update(:html, set: admin_flex, on: ".flex-nav section")
        |> exec_js(active_link_js(page))
        socket
      end

      def active_link_js(page) do
        """
        $('.flex-nav .wrapper li').removeClass('active');
        $('.flex-nav li a[data-id="#{page.id}"]').parent().addClass('active');
        """
        |> String.replace("\n", "")
      end

      def get_user!(%{assigns: %{user_id: user_id}}) do
        UcxUcc.Accounts.get_user! user_id, preload: [:account, :roles]
      end

      def has_permission?(user, permission, scope \\ nil) do
        UcxUcc.Permissions.has_permission?(user, permission, scope)
      end

      def has_role?(user, role, scope \\ nil),
        do: UcxUcc.Accounts.User.has_role?(user, role, scope)

      defoverridable [
        get_user!: 1,
        open: 3,
        args: 4,
        render_to_string: 1,
        has_permission?: 3,
        has_role?: 3
      ]
    end
  end

  defstruct [
    id: nil,
    module: nil,
    name: nil,
    view: nil,
    template: nil,
    order: 100,
    opts: []
  ]

  def new(id, module, name, view, template, order, opts \\ []) do
    new [
      id: id,
      module: module,
      name: name,
      view: view,
      template: template,
      order: order,
      opts: opts
    ]
  end

  def new(opts) do
    struct new(), opts
  end

  def new do
    __MODULE__.__struct__
  end

end
