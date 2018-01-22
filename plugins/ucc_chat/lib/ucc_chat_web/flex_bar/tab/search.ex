defmodule UccChatWeb.FlexBar.Tab.Search do
  @moduledoc """
  Search messages in the given room.

  Searching is done on the message body using the mysql `REGEXP` command.
  There are two search modes. If the user enters a series of words, they
  are turned into a REGEXP search as `word1|word2|word3`.

  However, if the user starts their search with the `/` character, then
  the complete contents of the search control is entered as a verbatim
  REGEX search.

  To ease the load on the database, searches are only performed for more
  than 2 characters. Additionally, searches are only performed every
  second. So, we are searching the database at most once a second while
  characters are being entered.
  """
  use UccChatWeb.FlexBar.Helpers

  import Rebel.Core
  import Phoenix.View, only: [render_to_string: 3]
  import UcxUccWeb.Gettext

  alias UcxUccWeb.Query
  alias UcxUcc.{TabBar.Tab, Accounts}
  alias UccChat.Message
  alias UccChatWeb.MessageView

  require Logger

  @no_results_found "<li style='padding-left: 20px;'><b>" <>
    ~g(No results found.) <> "</b></li>"

  # This controls the digit collection timer to limit the load on the
  # database queries. After this timeout the contents of the search
  # input control is retrieved and the database queried.
  @search_timeout 1_000

  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel direct im],
      "search",
      ~g"Search Messages",
      "icon-search",
      View,
      "search.html",
      15)
  end

  @doc """
  Handle the user's input, character by character.

  Called every time a character is entered. Starts the 1 second timer
  if is not already started. also checks the length of the search box
  and pushes the `No results found` response message it less than 2
  characters have been entered.
  """
  def search_input(socket, _sender) do
    unless Rebel.get_assigns(socket, :search_timer_ref) do
      timer_ref = Process.send_after(socket.channel_pid, {:forward_timeout,
        {__MODULE__, :update_search_results, [socket.assigns.__rebel_pid]}},
        @search_timeout)
      Rebel.put_assigns(socket, :search_timer_ref, timer_ref)
    end

    pattern = exec_js!(socket, "$('#message-search').val();")

    if String.length(pattern) <= 2 do
      Query.update(socket, :html, set: @no_results_found,
        on: ".main-content-flex ul.list")
    end

    socket
  end

  @doc """
  Query the database after the timer expires.

  The actual query is performed in a separate process so there will be
  no delay on the channel in case the query is heavy.
  """
  # def do_messages_args(collection, user_id, channel_id) do
  #   user = Accounts.get_user user_id
  #   collection
  #   |> Enum.reduce({nil, []}, fn m, {last_day, acc} ->
  #     day = DateTime.to_date(m.updated_at)
  #     msg =
  #       %{
  #         channel_id: channel_id,
  #         message: m.message,
  #         username: m.message.user.username,
  #         user: m.message.user,
  #         own: m.message.user_id == user_id,
  #         id: m.id,
  #         new_day: day != last_day,
  #         date: MessageView.format_date(m.message.updated_at, user),
  #         time: MessageView.format_time(m.message.updated_at, user),
  #         timestamp: m.message.timestamp
  #       }
  #     {day, [msg|acc]}
  #   end)
  #   |> elem(1)
  #   |> Enum.reverse
  # end
  def update_search_results(socket, rebel_pid) do
    # We are in the context to the UserChannel, not the Rebel callback.
    # So, we need to put the rebel_pid in the socket before we call
    # Rebel.put_assigns/3 and then drop the updated assigns/socket
    socket
    |> Phoenix.Socket.assign(:__rebel_pid, rebel_pid)
    |> Rebel.put_assigns(:search_timer_ref, nil)

    user = Accounts.get_user socket.assigns.user_id

    pattern = exec_js!(socket, "$('#message-search').val();")

    if String.length(pattern) > 2 do
      # Lets not delay the user socket here so we'll do the work in
      # a new process
      run_search_query(socket, user, pattern)
    else
      Query.update(socket, :html, set: @no_results_found, on:
        ".main-content-flex ul.list")
    end
  end

  defp run_search_query(socket, user, pattern) do
    channel_id = socket.assigns.channel_id

    spawn_link fn ->
      searches =
        channel_id
        |> Message.search_messages(user, pattern)
        |> process_search_results(user, channel_id)
        # |> Enum.reduce({nil, nil, []}, fn m, acc ->
        #   case {m.user_id, acc} do
        #     {u_id, {u_id, last_day, list}} ->
        #       m
        #       |> strucet
        #       search_args(struct(m, sequential: true), )
        #     {u_id, {_, last_day, list}} ->
        #       {u_id, [struct(m, sequential: false) | list]}
        #   end
        # end)
        # |> elem(1)
        # |> Enum.reverse

      html =
        if searches == [] do
          @no_results_found
        else
          render_to_string UccChatWeb.FlexBarView, "search_messages.html",
            [searches: searches, user: user]
        end

      Query.update(socket, :html, set: html, on: ".main-content-flex ul.list")
    end
  end

  defp process_search_results(collection, user, channel_id) do
    Enum.reduce(collection, {nil, nil, []}, fn m, {last_uid, last_day, acc} ->
      m = struct(m, sequential: m.user_id == last_uid)
      day =
        m.inserted_at
        |> MessageView.tz_offset(user)
        |> DateTime.to_date()

      msg =
        %{
          channel_id: channel_id,
          message: m,
          username: m.user.username,
          user: m.user,
          own: m.user_id == user.id,
          id: UUID.uuid1(),
          new_day: day != last_day,
          date: MessageView.format_date(m.inserted_at, user),
          time: MessageView.format_time(m.inserted_at, user),
          timestamp: m.timestamp
        }
      {m.user_id, day, [msg | acc]}
    end)
    |> elem(2)
    |> Enum.reverse
  end

end

