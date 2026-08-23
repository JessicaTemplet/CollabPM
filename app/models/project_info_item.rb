class ProjectInfoItem < ApplicationRecord
  include TenantScoped

  KINDS = %w[subscription cloud_dependency db_spec].freeze

  belongs_to :created_by, class_name: "User"

  validates :kind, inclusion: { in: KINDS }
  validates :name, presence: true
end
