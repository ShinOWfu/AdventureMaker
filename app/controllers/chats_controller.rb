class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end
end
