class ActivityLog < ApplicationRecord
  include TenantScoped

  belongs_to :actor, class_name: "User"
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, presence: true

  # Append-only: an audit trail that could be edited after the fact isn't
  # a trustworthy audit trail. Records are created once and never touched
  # again — correct a bad entry by writing a new one, not by mutating this.
  def readonly?
    persisted?
  end

  def self.record!(actor:, action:, subject: nil, payload: {})
    create!(actor: actor, action: action, subject: subject, payload: payload)
  end
end
