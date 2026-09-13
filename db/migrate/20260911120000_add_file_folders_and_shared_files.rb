class AddFileFoldersAndSharedFiles < ActiveRecord::Migration[8.1]
  def up
    create_table :file_folders do |t|
      t.bigint :tenant_id, null: false
      t.bigint :parent_id
      t.string :name, null: false
      t.timestamps
    end
    add_index :file_folders, :tenant_id
    add_index :file_folders, :parent_id
    add_index :file_folders, [ :tenant_id, :parent_id ]
    add_foreign_key :file_folders, :tenants
    add_foreign_key :file_folders, :file_folders, column: :parent_id

    create_table :shared_files do |t|
      t.bigint :tenant_id, null: false
      t.bigint :file_folder_id
      t.timestamps
    end
    add_index :shared_files, :tenant_id
    add_index :shared_files, :file_folder_id
    add_foreign_key :shared_files, :tenants
    add_foreign_key :shared_files, :file_folders

    migrate_existing_attachments_to_shared_files
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "would need to reattach blobs back onto Tenant#shared_files"
  end

  private

  # Existing uploads live as ActiveStorage attachments directly on Tenant
  # (has_many_attached :shared_files, flat, no folder tree). This
  # re-points each one onto a new SharedFile row instead of touching the
  # underlying blob, so nothing is re-uploaded or re-processed — only the
  # join record's owner changes, from Tenant to the new SharedFile.
  #
  # Anonymous AR classes on purpose, not the real Tenant/SharedFile
  # models — referencing application models from inside a migration
  # breaks once those models change shape later.
  def migrate_existing_attachments_to_shared_files
    attachment_class = Class.new(ActiveRecord::Base) { self.table_name = "active_storage_attachments" }
    shared_file_class = Class.new(ActiveRecord::Base) { self.table_name = "shared_files" }

    attachment_class.where(record_type: "Tenant", name: "shared_files").find_each do |attachment|
      shared_file = shared_file_class.create!(tenant_id: attachment.record_id)
      attachment.update!(record_type: "SharedFile", record_id: shared_file.id, name: "file")
    end
  end
end
