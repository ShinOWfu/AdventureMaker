class StoriesController < ApplicationController
  def new
    @story = Story.new
  end
  def create
    @story = Story.new(story_params)
    if @story.save
      redirect_to @story, notice: "A new story has begun!"
    else
      render :new, status: :unprocessable_entity
    end
  end
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
  def assessment
  end
end
