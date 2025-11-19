class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master storyteller who continues an interactive, continuous narrative; after the user gives their character’s actions,
respond with one short paragraph (3-6 sentences) that immersively describes the resulting events, maintains world and story continuity, never chooses actions for the user, and always moves the adventure forward."

  def create
    # @story = current_user.stories.find(params[:story_id])
    @chat  = Chat.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = 'user'
<<<<<<< HEAD
    if @message.save
      # ruby_llm_chat = RubyLLM.chat
      response = @chat.with_instructions(instructions).ask(@message.content)
      Message.create(role: "assistant", content: response.content, chat: @chat)
=======
>>>>>>> master


    if @message.save
      user_message_count = @chat.messages.where(role: 'user').count
      if user_message_count > 5
        redirect_to assessment_story_path(@chat.story), notice: 'Your adventure has concluded! Time for you personality assessment!'
      else
        response = @chat.with_instructions(instructions).ask(@message.content)
        message = Message.create(role: "assistant", content: response.content, chat: @chat)

        # image generation
        image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
        reply = image_chat.ask("generate a realistic looking image in #{@message.chat.story.genre} style following the story so far, and based on the user's next action here: #{response.content}")
        image = reply.content[:attachments][0].source
        message.image.attach(io: image, filename: "#.png", content_type: "image/png")
        message.save

        redirect_to chat_path(@chat)
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
    "Here is the context of the challenge: #{@message.content}."
  end

  def instructions
    [SYSTEM_PROMPT].compact.join("\n\n")
  end

end
