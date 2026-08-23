# Include in any tenant-scoped model that can carry tags. Tags are
# found-or-created per tenant by name, so two records tagging "urgent"
# share one Tag row instead of each minting their own.
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings
  end

  def tag_names=(names)
    self.tags = Array(names).map(&:to_s).map(&:strip).reject(&:blank?).uniq.map { |name|
      Tag.find_or_create_by!(tenant_id: tenant_id, name: name)
    }
  end
end
