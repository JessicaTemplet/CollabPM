class Notification < ApplicationRecord
  include TenantScoped

  belongs_to :recipient, class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :kind, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }

  def read!
    update!(read_at: Time.current) if read_at.nil?
  end
end
