class Message < ApplicationRecord
  acts_as_message tool_calls_foreign_key: :message_id
  has_one_attached :image

end
