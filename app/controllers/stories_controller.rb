class StoriesController < ApplicationController
  def new
    @story = Story.new
  end

  def create
    @story = Story.new(story_params)
    @chat = Chat.new
    @chat.story = @story
    @story.user = current_user
    if @story.save

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
      :assessment,
      :system_prompt,
      :protagonist_image
    )
  end
end
