class CreateOutreachContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :outreach_contacts do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :channel, null: false
      t.string :status, null: false, default: "planned"
      t.string :kind, null: false # "grassroots" | "paid"

      # Paid-specific — nullable, only meaningful when kind == "paid".
      t.integer :budget_cents
      t.string :campaign_name

      t.timestamps
    end

    add_index :outreach_contacts, [ :tenant_id, :kind ]
    add_index :outreach_contacts, [ :tenant_id, :status ]
  end
end
