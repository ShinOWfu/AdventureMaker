class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master fantasy adventure storyteller who continues an interactive, continuous narrative; after the user gives their character’s actions, respond with one short paragraph (3–6 sentences) that immersively describes the resulting events, maintains world and story continuity, never chooses actions for the user, and always moves the adventure forward."

  def create
    # @story = current_user.stories.find(params[:story_id])
    @chat  = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user'
    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)

      redirect_to chat_path(@chat)
    else
      render chat_path(@chat), status: :unprocessable_entity
    end
  end



  private

  def message_params
    params.require(:message).permit(:content, :role)
  end

  def message_context
    "Here is the context of the challenge: #{@message.content}."
  end

  def instructions
    [SYSTEM_PROMPT].compact.join("\n\n")
  end
end
