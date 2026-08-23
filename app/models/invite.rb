class Invite < ApplicationRecord
  include TenantScoped

  class AlreadyUsedError < StandardError; end

  belongs_to :created_by, class_name: "User"
  belongs_to :used_by, class_name: "User", optional: true

  GRANTABLE_ROLES = %w[admin member].freeze # never "owner" via invite — that's bootstrap-only

  validates :role, inclusion: { in: GRANTABLE_ROLES }
  validates :expires_at, presence: true
  validates :generation_limit, numericality: { greater_than: 0 }

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  # A dedicated, purpose-scoped verifier (Rails.application.message_verifier
  # derives its key from this name + secret_key_base) so an invite token can
  # never be replayed as some *other* signed payload the app produces, and
  # vice versa.
  def self.verifier
    Rails.application.message_verifier(:invite)
  end

  # Signature + expiry check ONLY — no DB query. Tampering with any field
  # (tenant_id, invite_id, generation) invalidates the signature and raises
  # here, before a single SQL statement runs. This is the cheap first-pass
  # filter, not the authorization decision: a signature staying valid does
  # NOT mean the invite is still usable (it may have already been redeemed,
  # or revoked) — see `usable_at_generation?`, which is the authoritative
  # check and always requires a fresh row.
  def self.decode_token(token)
    verifier.verify(token)
  end

  # tenant_id is embedded so `decode_token` alone can reject a token forged
  # for another tenant without a query. It is NEVER trusted on its own —
  # every call site re-checks it against the loaded record's real tenant_id.
  def token(generation: 0)
    self.class.verifier.generate(
      { "invite_id" => id, "tenant_id" => tenant_id, "generation" => generation },
      expires_at: expires_at
    )
  end

  def expired?
    expires_at <= Time.current
  end

  # The authoritative check. `generation` comes from the *token*, not the
  # row — it's how far this particular copy has been forwarded, and each
  # forwarded copy of the same invite carries its own generation.
  def usable_at_generation?(generation)
    used_at.nil? && !expired? && generation <= generation_limit
  end

  def record_forward!(generation:)
    update!(forward_log: forward_log + [ { "generation" => generation, "forwarded_at" => Time.current.iso8601 } ])
  end

  # Row-locked so two people redeeming forwarded copies of the same invite
  # at the same instant can't both win — the loser raises AlreadyUsedError
  # instead of silently double-granting membership.
  def redeem!(user:)
    with_lock do
      raise AlreadyUsedError if used_at.present?
      update!(used_at: Time.current, used_by: user)
    end
  end
end
