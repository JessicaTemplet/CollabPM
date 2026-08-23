class Event < ApplicationRecord
  include TenantScoped

  belongs_to :created_by, class_name: "User"

  validates :title, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validate :end_at_not_before_start_at

  # Broadcasts to a per-tenant stream, not a global one — Turbo's broadcast
  # job runs outside any request/ApplicationJob tenant context, so the
  # rendered partial deliberately touches only this record's own columns,
  # never a TenantScoped association (that would raise
  # TenantScoped::MissingTenantError with no Current.tenant set to restore).
  broadcasts_to ->(event) { [ event.tenant, :events ] }

  private

  def end_at_not_before_start_at
    return if start_at.blank? || end_at.blank?
    errors.add(:end_at, "must be on or after the start time") if end_at < start_at
  end
end
