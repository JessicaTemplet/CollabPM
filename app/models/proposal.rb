class Proposal < ApplicationRecord
  include TenantScoped
  include Commentable
  include Taggable

  # proposed -> changes_requested -> approved -> in_progress -> done
  # "denied" is a terminal branch off "proposed" only — once a proposal has
  # moved forward past that, rejecting it happens some other way (it's not
  # a status this model enforces beyond the guard below).
  STATUSES = %w[proposed changes_requested approved in_progress done denied].freeze

  belongs_to :created_by, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :denied_only_from_proposed, if: :status_changed?

  after_create { ActivityLog.record!(actor: created_by, action: "proposal.created", subject: self) }
  after_update :log_status_change, if: :saved_change_to_status?

  private

  def denied_only_from_proposed
    return unless status == "denied"
    errors.add(:status, "can only be set from proposed") unless status_was == "proposed"
  end

  def log_status_change
    from, to = saved_change_to_status
    # Current.user is nil outside a request (console, a future background
    # job) — fall back to the proposal's own author rather than raising on
    # ActivityLog's required actor.
    ActivityLog.record!(actor: Current.user || created_by, action: "proposal.status_changed", subject: self, payload: { from: from, to: to })
  end
end
