class OutreachContact < ApplicationRecord
  include TenantScoped

  STATUSES = %w[planned contacted responded converted declined].freeze
  KINDS = %w[grassroots paid].freeze

  belongs_to :created_by, class_name: "User"

  validates :name, presence: true
  validates :channel, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :kind, inclusion: { in: KINDS }
end
