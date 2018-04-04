defmodule OnePagesWeb.FeaturesView do
  use OnePagesWeb, :view


  def full_search_text do
    gettext """
      Fast and smart search, helping you look for messages, people and
      threads of conversation. Use Regular expressions to perform fine-grained
      searches.
      """
  end

  def private_conversations_text do
    gettext """
      As well as public rooms, communicate privately in with direct messages
      and private rooms. Promote a direct message conversation to a n-way chat
      by simply @-mentioning someone else. Add more people the same way.
      """
  end

end
