class LedgerEntry < ApplicationRecord
  include TenantScoped

  METHODS = %w[hourly deliverable].freeze
  ENTRY_TYPES = %w[value payment].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :subject, polymorphic: true, optional: true

  validates :method, inclusion: { in: METHODS }
  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :amount_cents, presence: true, numericality: { only_integer: true }
  validate :subject_required_for_value_entries

  # Append-only: corrections are a new offsetting entry (e.g. amount_cents
  # negated), never an edit to what already happened here — same rationale
  # as ActivityLog. This is the piece a financial trail can't afford to fudge.
  def readonly?
    persisted?
  end

  private

  def subject_required_for_value_entries
    errors.add(:subject, "is required for a value entry") if entry_type == "value" && subject.nil?
  end
end
