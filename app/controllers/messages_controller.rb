class MessagesController < ApplicationController

SYSTEM_PROMPT = "You are a master adventure and fantasy story teller. I am going through the story you give me base on the background i give you, and giving you my next actions. As i give you my actions, generate the next part of the story. Answer in the form of a short paragraph."

  def create
    @story = current_user.stories.find(params[:story_id])
    @message = Message.new(message_params)
    @message.story = @story
    @message.role = 'user'
    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)
      Message.create(role: "assistant", content: response.content, story: @story)

      redirect_to story_messages_path(@story)
    else
      render "story/new", status: :unprocessable_entity
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
    [SYSTEM_PROMPT, challenge_context].compact.join("\n\n")
  end
end
