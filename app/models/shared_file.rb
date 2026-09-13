# One uploaded file, optionally filed under a FileFolder (nil = root
# level). Replaces the old flat `Tenant.has_many_attached :shared_files`
# — giving each upload its own row is what lets it live inside a real
# folder tree instead of one undifferentiated list.
class SharedFile < ApplicationRecord
  include TenantScoped

  belongs_to :file_folder, optional: true
  has_one_attached :file

  validate :folder_belongs_to_same_tenant

  private

  def folder_belongs_to_same_tenant
    return if file_folder.nil?
    errors.add(:file_folder, "must belong to the same tenant") if file_folder.tenant_id != tenant_id
  end
end
