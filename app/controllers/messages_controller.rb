class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master story teller who continues an interactive, continuous narrative; after the user gives their character’s actions,
respond with one short paragraph (3-6 sentences) that immersively describes the resulting events, maintains world and story continuity, never chooses actions for the user, and always moves the adventure forward. The story should be paced so it comes to an end after receiving 5 messages from the user"

  def create
    # @story = current_user.stories.find(params[:story_id])
    @chat  = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user'

    if @message.valid?
      response = @chat.with_instructions(instructions).ask(@message.content)
      @user_message_count = @chat.messages.where(role: 'user').count
      @last_assistant_message = @chat.messages.where(role: "assistant").order(:created_at).last

      if @user_message_count > 4
        redirect_to assessment_story_path(@chat.story), notice: 'Your adventure has concluded! Time for you personality assessment!'
        return
      end
      # image generation
      ImageGeneratorJob.perform_later(@chat, @last_assistant_message, @chat.story)  
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
