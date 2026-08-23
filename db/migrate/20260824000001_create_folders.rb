class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :folders }
      t.string :name, null: false

      t.timestamps
    end

    add_index :folders, [ :tenant_id, :parent_id ]
  end
end
