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
      # Message.create(role: "assistant", content: @story_start, chat: @chat)
      # @chat.messages.create!(role: "system", content: @story_start)
      redirect_to chat_path(@chat), notice: "A new story has begun!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def assessment
    # Find the story by id
    @story = current_user.stories.find(params[:id])
    @chat = @story.chat

    # Execute ONLY if story.assessment is blank
    if @story.assessment.blank?
      # Get the last user message to generate the conclusion
      last_user_message = @chat.messages.where(role: 'user').last

      # Generate the final story conclusion
      story_ending_prompt = "You are a master storyteller concluding an interactive narrative. " \
                          "Based on the user's final action, write a dramatic ending to their story. " \
                          "Make it feel final and complete. 2-3 sentences maximum." \
                          "Write the ultimate conclusion to their story."

      story_chat = RubyLLM.chat
      final_story_content = story_chat.ask(story_ending_prompt).content

      # Save the ending, so now story includes 5 user decisions and 6 AI replies
      final_message = Message.create!(
      role: "assistant",
      content: final_story_content,
      chat: @chat
      )

      # Generate the final image
      image_prompt = "Generate a dramatic, cinematic final scene for this story that captures the ENTIRE journey. " \
                     "Create an image that shows the culmination of their adventure - include visual callbacks to key moments " \
                     "from their journey, the protagonist's transformation, and the final outcome. The composition should tell " \
                     "the story of where they started, what they went through, and how it all ended. Make it epic, emotionally " \
                     "powerful, and visually capture the essence of their complete adventure from beginning to end."

      image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
      image_reply = image_chat.ask(image_prompt)
      image_source = image_reply.content[:attachments][0].source

      # Attach to the final message, save the file as something more descriptive
      final_message.image.attach(io: image_source, filename: "ending_#{final_message.id}.png", content_type: "image/png")
      final_message.save

      # Prompt with line jumps for easier readability including the conversation
      assessment_prompt = "You're a therapist who is TIRED and barely hiding your judgment. Analyze their story choices " \
                        "with thinly-veiled sarcasm and backhanded compliments." \
                        "Start with 'Well, that was... certainly a choice.' Use phrases like 'bless your heart', " \
                        "'interesting approach', and 'I'm sure that made sense to YOU'. One paragraph of polite savagery " \
                        "disguised as professional assessment. Stay passive-aggressive throughout."

      # Prompt the AI with the assessment
      ruby_llm_chat = RubyLLM.chat
      @assessment = ruby_llm_chat.ask(assessment_prompt).content

      # Save the assessment so no need to prompt AI every time we get into the story and we can revisit later.
      @story.update!(assessment: @assessment)
    end
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
