# Searches or queries for conversations associated with the account and query
# if present.
class ConversationsInbox
  include ConversationsMethods
  include ConversationsSearch

  attr_accessor :account, :user, :query

  def initialize(account, user, query = nil)
    self.account = account
    self.user = user
    self.query = clean_query(query)
  end

  # Public: Returns conversations matching search results if present.
  # Otherwise, the conversations are returned in order of least recent message.
  #
  # Returns an Array or ActiveRecord::Relation of Conversation models.
  def conversations
    if search?
      search_conversations
    else
      conversations_queue
    end
  end

  # Public: Finds all the open conversations and sorts them in order of least
  # recent message.
  #
  # Returns an Array of Conversation models.
  def conversations_queue
    @conversations_queue ||= open_conversations.joins("LEFT OUTER JOIN respond_laters ON conversations.id = respond_laters.conversation_id AND respond_laters.user_id = '#{user.id}'").
      order('respond_laters.updated_at ASC NULLS FIRST, conversations.updated_at DESC')
  end

  # Public: Finds the next conversation in the queue after the
  # conversation argument
  #
  # Returns a Conversation model or nil if the argument is the last
  # conversation in the inbox
  def next_after(conversation)
    index = conversations_queue.index { |c| c == conversation }
    conversations_queue[index + 1]
  end

  # Public: Finds all the open conversations associated with the account.
  #
  # Returns an ActiveRecord::Relation of Conversation models.
  def open_conversations
    preloaded_conversations.unresolved
  end
end
