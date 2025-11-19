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
      @story_start= @chat.ask("You are the DM for a text-based RPG-style game. The genre is #{@story.genre} and the context is #{@story.topic}. The player's character's name is #{@story.protagonist_name} and his detailed description is #{@story.protagonist_description}.")
      # Message.create(role: "assistant", content: @story_start, chat: @chat)
      # @chat.messages.create!(role: "system", content: @story_start)
    
      redirect_to chat_path(@chat), notice: "A new story has begun!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def assessment
    @story = current_user.stories.find(params[:id])
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
