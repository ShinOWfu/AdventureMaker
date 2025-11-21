class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
    @user_message_count = @chat.messages.where(role: 'user').count
    @assistant_message = @chat.messages.where(role: 'assistant').order(:created_at).last
  end
end
