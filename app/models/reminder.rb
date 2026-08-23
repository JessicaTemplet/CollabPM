class Reminder < ApplicationRecord
  include TenantScoped

  STATUSES = %w[pending delivered].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :subject, polymorphic: true, optional: true

  validates :remind_at, presence: true
  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :due, -> { where(remind_at: ..Time.current) }

  def deliver!
    Notifier.notify(recipient: created_by, kind: "reminder", message: message, notifiable: subject)
    update!(status: "delivered")
  end
end
