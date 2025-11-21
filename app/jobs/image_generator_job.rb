class ImageGeneratorJob < ApplicationJob
  queue_as :default
  include ActionView::RecordIdentifier

  def perform(chat, last_assistant_message)
    image_chat = RubyLLM.chat(model: "gemini-2.5-flash-image")
    reply = image_chat.ask("Generate an image based on this text #{last_assistant_message.content} and use the attached picture of the protagonist", with: { image: chat.story.protagonist_image.url })
    image = reply.content[:attachments][0].source
    last_assistant_message.image.attach(io: image, filename: "#.png", content_type: "image/png")
    last_assistant_message.save
    Turbo::StreamsChannel.broadcast_update_to(chat, target: dom_id(last_assistant_message), partial: "messages/image", locals: { message: last_assistant_message })
  end
end
