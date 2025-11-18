class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master adventure and fantasy story teller. I am going through the story you give me base on the background i give you, and giving you my next actions. As i give you my actions, generate the next part of the story. Answer in the form of a short paragraph."

  def create
    @story = current_user.stories.find(params[:id])
    @message = Message.new(message_params)
    @message.story = @story
  end



  private

  def message_params
  end
end
