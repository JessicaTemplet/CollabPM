class Tag < ApplicationRecord
  include TenantScoped

  has_many :taggings, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :tenant_id, case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip.downcase }
end
