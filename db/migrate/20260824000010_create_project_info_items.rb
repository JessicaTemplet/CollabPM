class CreateProjectInfoItems < ActiveRecord::Migration[8.1]
  def change
    create_table :project_info_items do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false # "subscription" | "cloud_dependency" | "db_spec"
      t.string :name, null: false
      # Kind-specific fields (e.g. cost/renewal date for a subscription,
      # provider for a cloud dependency) live here rather than as columns —
      # manual entry for now; still open whether this later gets fed by
      # Anagraphe instead of typed in by hand.
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end

    add_index :project_info_items, [ :tenant_id, :kind ]
  end
end
