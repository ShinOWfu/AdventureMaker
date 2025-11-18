class Story < ApplicationRecord
  belongs_to :user
  has_one :chat
  validates :protagonist_name, :genre, presence: true
  validates :protagonist_name, length: { maximum: 15 }
  validates :protagonist_description, length: { maximum: 200 }
  has_one_attached :protagonist_image
end
