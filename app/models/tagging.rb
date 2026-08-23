class Tagging < ApplicationRecord
  include TenantScoped

  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  validates :tag_id, uniqueness: { scope: [ :taggable_type, :taggable_id ] }
end
