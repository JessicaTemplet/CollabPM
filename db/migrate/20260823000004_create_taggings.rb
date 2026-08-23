class CreateTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :taggings do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :taggings, [ :tag_id, :taggable_type, :taggable_id ], unique: true,
      name: "index_taggings_on_tag_and_taggable"
  end
end
