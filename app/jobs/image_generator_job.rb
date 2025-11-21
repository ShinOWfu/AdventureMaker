class ImageGeneratorJob < ApplicationJob
  queue_as :default
  include ActionView::RecordIdentifier

  def perform(chat, last_assistant_message, story)
    image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
    # Trying to feed the last image as input so that the images stay consistent
    messages_with_images = story.chat.messages.select { |m| m.image.attached? }
    last_image = messages_with_images.last.image.url if messages_with_images.any?
     # Line below is the image call where I pass the image as input
    reply = image_chat.ask("Generate an image based on this text #{last_assistant_message.content} and use the attached picture of the protagonist. The style of the generated image should be similar with the last image", with: [chat.story.protagonist_image.url, last_image] )
    image = reply.content[:attachments][0].source
    last_assistant_message.image.attach(io: image, filename: "#.png", content_type: "image/png")
    last_assistant_message.save
    Turbo::StreamsChannel.broadcast_update_to(chat, target: dom_id(last_assistant_message), partial: "messages/image", locals: { message: last_assistant_message })
  end
end



