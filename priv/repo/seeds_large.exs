alias InfinityOne.Accounts
alias OneChat.{Message, Channel}

messages = [
    "Give me some of that very fine food from that there box",
    "Once in a while I can see that you are in for a hard time",
    "When will you give me the key to your big red car",
    "What is the time over there when the hand is down",
    "Ask me again what time does your house get cleaned",
    "The three red balls rolled down the path with great speed",
    "I wish that hat would fit on my head when it rains in the morning",
    "What time did you wake up today and did it snow down there",
    "This was a great time for that thing to be opened by them",
    "When will I get my new toys to play with now that the sun is shining",
    "Its too bad that he was on the top of that hill when the fire broke",
    "There are all small things to type so it should not be very hard",
    "How many of there things do i have to try before I can start",
    "Today marks the first day of the new year so we should get busy",
    "How many times can you say that mine will always be there",
    "Twas the night before Christmas and the kids where all snuggled in bed",
    "There are too many ways to count them when you are above all",
    "Before one there was another that was before this and that",
    "The cat ran with the dog into their home with some more",
    "This and that was with the more and with all of them here or there",
    "Where are you when you are where you are for one time or another",
    "With one and three will amount to five after six and seven",
    "So there you are with all of them and more will cause better things",
    "Once upon a time there was a small boy with a big heart",
    "That was then and this is now but then will be now or then",
    "My new thing will bring some new and old items between there",
    "Sorry, I can't make it tonight. Lets talk tomorrow",
    "Are you free to go out tonight?",
    "Have you ever eaten a frozen dinner?",
    "I am working on the architecture right now",
    "When can we release the alpha version of the product?",
    "How many bugs did you fix yesterday and today?",

    "How are you enjoying your new home?",
    "I bought a new laptop on the weekend from the apple store.",
    "Did he happen to mention that we are leaving on the weekend.",
    "I'm heading to the gym in a 10 minutes.",
    """
    This is a multi sentence message.
    Here is the second sentence.
    """,
    "I'm happy with that :smile:",
    ":smile:",
    "Are you feeling good? :)",
    "Check the `intercept` variable.",
    "Ok. That will work for me.",
    "My dog ate my homework",
    "I told you, that won't work that way.",
    "99 bottles of beer on the wall.",
    "Another on bites the dust.",
    "hello there",
    "what's up doc",
    "are you there?",
    "Did you get the join?",
    "When will you be home?",
    "Be right there!",
    "Can't wait to see you!",
    "What did you watch last night?",
    "Is your homework done yet?",
    "what time is it?",
    "whats for dinner?",
    "are you sleeping?",
    "how did you sleep last night?",
    "did you have a good trip?",
    "Tell me about your day",
    "be home by 5 please",
    "wake me up a 9 please",
    "ttyl",
    "cul8r",
    "hope it works",
    "Let me tell you a story about a man named Jed",
  ]

usernames = ~w(steve jason jamie ardavan simon eric jeff merilee)

chan_name =
  case System.argv do
    [] -> "BigRoom"
    [name | _] -> name
  end

channel = Channel.get_by(name: chan_name) || raise("invalid channel name")
user_ids = Enum.map usernames, fn name ->
  Accounts.get_by_username(name) |> Map.get(:id)
end

count = 300
grouping = 5

IO.puts "Starting to generate #{count} to #{count * grouping} messages"

Enum.reduce(1..count, {1, []}, fn _, {cnt, acc} ->
  gr = :rand.uniform(grouping) - 1
  lst = for inx <- (cnt..(cnt + gr)), do: inx
  {cnt + gr + 1, [lst|acc]}
end)
|> elem(1)
|> Enum.reverse
|> Enum.each(fn sub ->
  id = Enum.random user_ids
  IO.inspect sub
  for inx <- sub do
    Message.create!(%{channel_id: channel.id, user_id: id, body: "#{inx} " <> Enum.random(messages)})
    Process.sleep(1000)
  end
end)


# for cnt <- 1..count do
#   if rem(cnt, 25) == 0, do: IO.puts("Creating #{cnt}th message group ...")
#   id = Enum.random user_ids

#   for _ <- 1..(:rand.uniform(grouping)) do
#     Message.create!(%{channel_id: channel.id, user_id: id, body: Enum.random(messages)})
#   end
# end
