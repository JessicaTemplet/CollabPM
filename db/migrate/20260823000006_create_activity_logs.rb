class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :subject, polymorphic: true
      t.string :action, null: false
      t.jsonb :payload, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :activity_logs, [ :tenant_id, :created_at ]
    add_index :activity_logs, [ :subject_type, :subject_id ]
  end
end
