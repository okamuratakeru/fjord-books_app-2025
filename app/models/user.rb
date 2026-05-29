# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  validate :avatar_content_type

  private

  def avatar_content_type
    return unless avatar.attached?

    return if avatar.blob.image?

    errors.add(:avatar, :invalid)
  end
end
