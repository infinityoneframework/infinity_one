defmodule OneAdmin.Page do
  defmacro __using__(_) do
    quote location: :keep do
      import unquote(__MODULE__)
      import InfinityOneWeb.Gettext
      import Rebel.Core, warn: false
      import Rebel.Query, warn: false

      alias OneAdminWeb.AdminChannel
      alias OneChatWeb.RebelChannel.SideNav
      alias InfinityOneWeb.Query

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
        |> Query.update(:html, set: html, on: ".main-content")
        |> Query.update(:html, set: admin_flex, on: ".flex-nav section")
        |> async_js(active_link_js(page))
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
        InfinityOne.Accounts.get_user! user_id, preload: [:account, :roles, user_roles: :role]
      end

      def has_permission?(user, permission, scope \\ nil) do
        InfinityOne.Permissions.has_permission?(user, permission, scope)
      end

      def has_role?(user, role),
        do: InfinityOne.Accounts.has_role?(user, role)

      def has_role?(user, role, scope),
        do: InfinityOne.Accounts.has_role?(user, role, scope)

      defoverridable [
        get_user!: 1,
        open: 3,
        args: 4,
        render_to_string: 1,
        has_permission?: 3,
        has_role?: 3,
        has_role?: 2
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
