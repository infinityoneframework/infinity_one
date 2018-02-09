defmodule UcxUcc.Hooks do
  @moduledoc """

  """
  use Unbrella.Hooks, :defhooks

  defhook :preload_user, 2, doc: """
    Preload a user.

    ## Examples

        def preload_user(user, preload) do
          Repo.preload user, [:my_repload | preload]
        end
    """

  defhook :user_preload, 1, doc: """
    Add to list of preloads used when loading a user

    ## Examples

        def user_preload(preload) do
          [:my_preload | preload]
        end

    """

  defhook :all_users_post_filter, 1, doc: """
    Post process a list of users.

    ## Examples

        def all_users_post_filter(users) do
          Enum.map(users, fn user ->
            Map.put(user, :password, "")
          end)
        end
    """

  defhook :process_user_subscription, 1, doc: """
    Process list of {user, subscription} tuples.
    """

  defhook :render_users_bindings, 1, doc: """
    Process binding for rendering users
    """

  defhook :user_details_thead_hook, 1, doc: """
    Add items to the table head.
    """

  defhook :user_details_body_hook, 2, doc: """
    Add items to the users details body.
    """

  defhook :user_card_details, 2
  defhook :user_list_item_hook, 2
  defhook :messages_header_icons, 2
  defhook :account_box_header, 2
  defhook :nav_option_buttons, 1
  defhook :nav_room_item_icons, 2
  defhook :account_box_class, 1

  defhook :add_flex_buttons, 0
  defhook :ucc_chat_channel_controller_channels, 1

  defhook :register_admin_pages, 1
  defhook :build_sidenav_room, 1
  defhook :update_host, 1, doc: """
    Notify a change in the Endpoint [url: [host: host_name]]
    """
  defhook :update_email_from , 1, doc: """
    Notify a change in the email from settings.
    """
end
