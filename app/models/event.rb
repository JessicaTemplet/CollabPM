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
  #
  # Explicit append/remove rather than the broadcasts_to shorthand: the
  # calendar renders each event inside its own day cell, not one flat list,
  # so the insert target (that day's dom id) and the remove target (the
  # event's own dom id) are genuinely different elements. broadcast_remove_to
  # already defaults to dom_id(self), which is exactly the chip's own id
  # regardless of which day cell it's nested in, so destroy needs no target.
  after_create_commit -> {
    broadcast_append_to [ tenant, :events ],
      target: "day-#{start_at.to_date.iso8601}",
      partial: "events/event_chip",
      locals: { event: self }
  }
  after_destroy_commit -> {
    broadcast_remove_to [ tenant, :events ]
  }

  private

  def end_at_not_before_start_at
    return if start_at.blank? || end_at.blank?
    errors.add(:end_at, "must be on or after the start time") if end_at < start_at
  end
end
