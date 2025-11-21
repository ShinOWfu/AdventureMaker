class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master story teller who continues an interactive, continuous narrative; after the user gives their character’s actions,
respond with one short paragraph (3-6 sentences) that immersively describes the resulting events, maintains world and story continuity, never chooses actions for the user, and always moves the adventure forward."

  def create
    # @story = current_user.stories.find(params[:story_id])
    @chat  = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user'
    @user_message_count = @chat.messages.where(role: 'user').count

    if @message.valid?
      begin
        response = @chat.with_instructions(instructions).ask(@message.content)
        @last_assistant_message = @chat.messages.where(role: "assistant").order(:created_at).last

        if @user_message_count > 4
          redirect_to assessment_story_path(@chat.story), notice: 'Your adventure has concluded! Time for you personality assessment!'
        end

        # image generation
        ImageGeneratorJob.perform_later(@chat, @last_assistant_message)
        redirect_to chat_path(@chat)

      rescue RubyLLM::Error => e
        Rails.logger.error "LLM Error: #{e.message}"
        @chat.messages.order(:created_at).where(role: 'user').last.destroy
        redirect_to chat_path(@chat), notice: 'The storyteller is currently overwhelmed. Please try again in a moment.'
      end

    else
      render chat_path(@chat), status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :role)
  end

  def message_context
    "Here is the context of the message: #{@message.content}."
  end

  def instructions
    [SYSTEM_PROMPT].compact.join("\n\n")
  end
end
