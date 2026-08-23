# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_24_000015) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.bigint "tenant_id", null: false
    t.index ["actor_id"], name: "index_activity_logs_on_actor_id"
    t.index ["subject_type", "subject_id"], name: "index_activity_logs_on_subject"
    t.index ["subject_type", "subject_id"], name: "index_activity_logs_on_subject_type_and_subject_id"
    t.index ["tenant_id", "created_at"], name: "index_activity_logs_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_activity_logs_on_tenant_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id", "created_at"], name: "index_comments_on_commentable_and_created_at"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["tenant_id"], name: "index_comments_on_tenant_id"
  end

  create_table "document_ops", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "document_id", null: false
    t.bigint "fugue_counter", null: false
    t.string "fugue_replica", null: false
    t.string "op_type", null: false
    t.bigint "parent_counter"
    t.string "parent_replica"
    t.string "side"
    t.bigint "tenant_id", null: false
    t.text "value"
    t.index ["document_id", "created_at"], name: "index_document_ops_on_document_id_and_created_at"
    t.index ["document_id", "fugue_replica", "fugue_counter", "op_type"], name: "index_document_ops_on_document_and_fugue_id", unique: true
    t.index ["document_id"], name: "index_document_ops_on_document_id"
    t.index ["tenant_id"], name: "index_document_ops_on_tenant_id"
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "folder_id"
    t.jsonb "fugue_snapshot"
    t.bigint "snapshot_through_op_id"
    t.bigint "tenant_id", null: false
    t.string "title", default: "Untitled", null: false
    t.datetime "updated_at", null: false
    t.index ["folder_id"], name: "index_documents_on_folder_id"
    t.index ["snapshot_through_op_id"], name: "index_documents_on_snapshot_through_op_id"
    t.index ["tenant_id"], name: "index_documents_on_tenant_id"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "all_day", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.datetime "end_at", null: false
    t.datetime "start_at", null: false
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["tenant_id", "start_at"], name: "index_events_on_tenant_id_and_start_at"
    t.index ["tenant_id"], name: "index_events_on_tenant_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_folders_on_parent_id"
    t.index ["tenant_id", "parent_id"], name: "index_folders_on_tenant_id_and_parent_id"
    t.index ["tenant_id"], name: "index_folders_on_tenant_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.datetime "expires_at", null: false
    t.jsonb "forward_log", default: [], null: false
    t.integer "generation_limit", default: 3, null: false
    t.string "role", default: "member", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "used_by_id"
    t.index ["created_by_id"], name: "index_invites_on_created_by_id"
    t.index ["tenant_id", "used_at"], name: "index_invites_on_tenant_id_and_used_at"
    t.index ["tenant_id"], name: "index_invites_on_tenant_id"
    t.index ["used_by_id"], name: "index_invites_on_used_by_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.string "entry_type", null: false
    t.string "method", null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.bigint "tenant_id", null: false
    t.index ["created_by_id"], name: "index_ledger_entries_on_created_by_id"
    t.index ["subject_type", "subject_id"], name: "index_ledger_entries_on_subject"
    t.index ["subject_type", "subject_id"], name: "index_ledger_entries_on_subject_type_and_subject_id"
    t.index ["tenant_id", "entry_type"], name: "index_ledger_entries_on_tenant_id_and_entry_type"
    t.index ["tenant_id"], name: "index_ledger_entries_on_tenant_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.string "message", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.bigint "tenant_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["tenant_id"], name: "index_notifications_on_tenant_id"
  end

  create_table "outreach_contacts", force: :cascade do |t|
    t.integer "budget_cents"
    t.string "campaign_name"
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.string "status", default: "planned", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_outreach_contacts_on_created_by_id"
    t.index ["tenant_id", "kind"], name: "index_outreach_contacts_on_tenant_id_and_kind"
    t.index ["tenant_id", "status"], name: "index_outreach_contacts_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_outreach_contacts_on_tenant_id"
  end

  create_table "project_info_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.jsonb "details", default: {}, null: false
    t.string "kind", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_project_info_items_on_created_by_id"
    t.index ["tenant_id", "kind"], name: "index_project_info_items_on_tenant_id_and_kind"
    t.index ["tenant_id"], name: "index_project_info_items_on_tenant_id"
  end

  create_table "proposals", force: :cascade do |t|
    t.bigint "assignee_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.date "due_date"
    t.string "status", default: "proposed", null: false
    t.bigint "tenant_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_proposals_on_assignee_id"
    t.index ["created_by_id"], name: "index_proposals_on_created_by_id"
    t.index ["tenant_id", "assignee_id"], name: "index_proposals_on_tenant_id_and_assignee_id"
    t.index ["tenant_id", "status"], name: "index_proposals_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_proposals_on_tenant_id"
  end

  create_table "reminders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "message", null: false
    t.datetime "remind_at", null: false
    t.string "status", default: "pending", null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_reminders_on_created_by_id"
    t.index ["status", "remind_at"], name: "index_reminders_on_status_and_remind_at"
    t.index ["subject_type", "subject_id"], name: "index_reminders_on_subject"
    t.index ["tenant_id"], name: "index_reminders_on_tenant_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "taggable_type", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_on_tag_and_taggable", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
    t.index ["tenant_id"], name: "index_taggings_on_tenant_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "name"], name: "index_tags_on_tenant_id_and_name", unique: true
    t.index ["tenant_id"], name: "index_tags_on_tenant_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_tenants_on_subdomain", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "email_address"], name: "index_users_on_tenant_id_and_email_address", unique: true
    t.index ["tenant_id"], name: "index_users_on_tenant_id"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_name"
    t.string "external_id", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["source", "external_id"], name: "index_webhook_events_on_source_and_external_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "tenants"
  add_foreign_key "activity_logs", "users", column: "actor_id"
  add_foreign_key "comments", "tenants"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "document_ops", "documents"
  add_foreign_key "document_ops", "tenants"
  add_foreign_key "documents", "document_ops", column: "snapshot_through_op_id"
  add_foreign_key "documents", "folders"
  add_foreign_key "documents", "tenants"
  add_foreign_key "events", "tenants"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "folders", "folders", column: "parent_id"
  add_foreign_key "folders", "tenants"
  add_foreign_key "invites", "tenants"
  add_foreign_key "invites", "users", column: "created_by_id"
  add_foreign_key "invites", "users", column: "used_by_id"
  add_foreign_key "ledger_entries", "tenants"
  add_foreign_key "ledger_entries", "users", column: "created_by_id"
  add_foreign_key "notifications", "tenants"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "outreach_contacts", "tenants"
  add_foreign_key "outreach_contacts", "users", column: "created_by_id"
  add_foreign_key "project_info_items", "tenants"
  add_foreign_key "project_info_items", "users", column: "created_by_id"
  add_foreign_key "proposals", "tenants"
  add_foreign_key "proposals", "users", column: "assignee_id"
  add_foreign_key "proposals", "users", column: "created_by_id"
  add_foreign_key "reminders", "tenants"
  add_foreign_key "reminders", "users", column: "created_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "taggings", "tenants"
  add_foreign_key "tags", "tenants"
  add_foreign_key "users", "tenants"
end
