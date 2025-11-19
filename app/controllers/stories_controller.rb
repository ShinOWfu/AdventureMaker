class StoriesController < ApplicationController
  def new
    @story = Story.new
  end

  def create
    # initialize the story and chat
    @story = Story.new(story_params)
    @chat = Chat.new

    # set up the chat for transfer
    @chat.story = @story
    @story.user = current_user

    if @story.save
      # 11/18 -- this is the line we need to change. We need to give the AI the story and make this line the AI's
      @story_start= @chat.ask("You are a master storyteller. You are creating a the setting for a new story.The genre is #{@story.genre} and the context is #{@story.topic}. The player's character's name is #{@story.protagonist_name} and his detailed description is #{@story.protagonist_description}. Create an initial setup that places the protagonist in this new world. This should only be one short paragraph long and not end in a question")

      redirect_to chat_path(@chat), notice: "A new story has begun!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def assessment
    # Find the story by id
    @story = current_user.stories.find(params[:id])
    @chat = @story.chat

    # Build full conversation history with roles for context
    conversation = @chat.messages.order(:created_at).map do |msg|
    "#{msg.role}: #{msg.content}"
    end.join("\n\n")

    # Prompt with line jumps for easier readability including the conversation
    prompt = "Act as a chaotic, comedic psychologist.\n" \
         "Provide a one-paragraph, funny assessment based on the full story and their adventure choices:\n\n" \
         "#{conversation}\n\n" \
         "Be dramatic, exaggerated, and confidently unhinged.\n" \
         "Do not break character.\n" \
         "Output exactly one humorous paragraph."

    # Prompt the AI with the assessment
    ruby_llm_chat = RubyLLM.chat
    @assessment = ruby_llm_chat.ask(prompt).content

    # Save the assessment so no need to prompt AI every time we get into the story and we can revisit later.
    @story.update!(assessment: @assessment)
  end

  private

  def story_params
    params.require(:story).permit(
      :protagonist_name,
      :protagonist_description,
      :genre,
      :topic,
      # :assessment,
      # :system_prompt,
      :protagonist_image
    )
  end
end
