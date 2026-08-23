# Include in any tenant-scoped model that can carry comments (Proposals
# first; any future module gets this for free).
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
  end
end
