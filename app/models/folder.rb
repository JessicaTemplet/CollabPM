class Folder < ApplicationRecord
  include TenantScoped

  belongs_to :parent, class_name: "Folder", optional: true
  has_many :children, class_name: "Folder", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :documents, dependent: :nullify

  validates :name, presence: true
  validate :parent_belongs_to_same_tenant

  private

  def parent_belongs_to_same_tenant
    return if parent.nil?
    errors.add(:parent, "must belong to the same tenant") if parent.tenant_id != tenant_id
  end
end
