class StoriesController < ApplicationController

  def index
    @stories = Story.all
  end

  def new
    @story = Story.new
  end

  def show
    @story = Story.find(params[:id])

    if @story.assessment.present?
      redirect_to assessment_story_path(@story)
    else
      redirect_to chat_path(@story.chat)
    end
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
      story_start_prompt = "You are a master storyteller creating an opening scene. " \
                          "Genre: #{@story.genre}. Setting: #{@story.topic}. " \
                          "Protagonist: #{@story.protagonist_name} - #{@story.protagonist_description}. " \
                          "Write one vivid paragraph (4-5 sentences) that drops the protagonist into this world. " \
                          "Set the scene with sensory details and immediate atmosphere. " \
                          "End with a moment of tension or choice, not a question."

      @story_start= @chat.ask(story_start_prompt)
      # Message.create(role: "assistant", content: @story_start, chat: @chat)
      # @chat.messages.create!(role: "system", content: @story_start)
      @message = Message.last

      initial_image_prompt = "Create an opening scene illustration for this story: #{@message.content} " \
                       "VISUAL: Show the protagonist in their starting environment with atmospheric detail. " \
                       "STYLE: Fantasy illustration, painterly, dramatic lighting. " \
                       "Use the attached image as character reference for the protagonist."

      image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
      reply = image_chat.ask(initial_image_prompt, with: {image: @story.protagonist_image.url })
      image = reply.content[:attachments][0].source
      @message.image.attach(io: image, filename: "#.png", content_type: "image/png")
      @message.save
      redirect_to chat_path(@chat), notice: "A new story has begun!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def assessment
    # Find the story by id
    @story = current_user.stories.find(params[:id])
    @chat = @story.chat
    @chat.messages.reload

    # Execute ONLY if story.assessment is blank
    if @story.assessment.blank?
      # Get the last user message to generate the conclusion
      last_user_message = @chat.messages.where(role: 'user').last

      # Generate the final story conclusion
      story_ending_prompt = "Write a dramatic 2-3 sentence conclusion to this story based on the user's final choice: '#{last_user_message.content}' " \
                            "Make it emotionally resonant and definitive - this is the final moment of their journey."

      @final_story_content = @chat.ask(story_ending_prompt).content

      # Save the ending, so now story includes 5 user decisions and 6 AI replies
      @final_message = Message.create!(
      role: "assistant",
      content: @final_story_content,
      chat: @chat
      )

      # Generate the final image
      image_prompt = "Create a dramatic final scene illustration based on this story ending: #{@final_story_content} " \
                      "VISUAL: " \
                      "- Center the protagonist in their climactic moment " \
                      "- Background hints at 2-3 key locations from their journey " \
                      "- Lighting: Dramatic contrast - golden glow for triumph, stormy for tragedy " \
                      "- Composition: Cinematic wide shot, rule-of-thirds " \
                      "STYLE: Fantasy book cover art, painterly, detailed protagonist " \
                      "AVOID: Text overlays, cluttered compositions"

      image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
      image_reply = image_chat.ask(image_prompt, with: {image: @story.protagonist_image.url})
      image_source = image_reply.content[:attachments][0].source

      # Attach to the final message, save the file as something more descriptive
      @final_message.image.attach(io: image_source, filename: "ending_#{@final_message.id}.png", content_type: "image/png")
      @final_message.save!
      @final_message.image.reload
      @chat.messages.reload

      # Prompt with line jumps for easier readability including the conversation
      assessment_prompt = "You're a witty therapist analyzing this user's story choices with playful sarcasm. " \
                          "Write ONE paragraph (4-6 sentences) of 'professional' assessment that's " \
                          "secretly roasting their choices with passive-aggressive observations. " \
                          "Tone: Politely savage, like a disappointed guidance counselor. " \
                          "Format: Plain text, no formatting."

      # Prompt the AI with the assessment
      @assessment = @chat.ask(assessment_prompt).content

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
