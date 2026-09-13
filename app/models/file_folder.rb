# A dedicated folder tree for Shared Files. Deliberately its own table
# rather than reusing the Folder model from the Documents/collaborative-
# editor feature (app/models/folder.rb) — same shape (self-referential
# tree, tenant-scoped), but files and documents are different features
# with different lifecycles, and nothing asked for those two to merge
# into one tree.
class FileFolder < ApplicationRecord
  include TenantScoped

  belongs_to :parent, class_name: "FileFolder", optional: true
  has_many :children, class_name: "FileFolder", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent

  # :destroy, not :nullify — deleting a folder deletes what's inside it,
  # same as deleting a folder on your own computer would.
  has_many :shared_files, dependent: :destroy

  validates :name, presence: true
  validate :parent_belongs_to_same_tenant

  private

  def parent_belongs_to_same_tenant
    return if parent.nil?
    errors.add(:parent, "must belong to the same tenant") if parent.tenant_id != tenant_id
  end
end
