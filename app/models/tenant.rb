class Tenant < ApplicationRecord
  include Commentable # a tenant-wide message board is just comments on the tenant itself

  SUBDOMAIN_FORMAT = /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/
  RESERVED_SUBDOMAINS = %w[www app api admin billing webhooks assets mail].freeze

  has_many :users, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :proposals, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :ledger_entries, dependent: :destroy
  has_many :project_info_items, dependent: :destroy
  has_many :outreach_contacts, dependent: :destroy
  has_many :reminders, dependent: :destroy

  # A shared drop-folder for the tenant. Each upload is its own SharedFile
  # row (see app/models/shared_file.rb) so it can live inside a real
  # FileFolder tree, browsable the way a normal file manager works.
  has_many :file_folders, dependent: :destroy
  has_many :shared_files, dependent: :destroy

  before_validation { subdomain&.downcase!&.strip! }

  validates :name, presence: true
  validates :subdomain,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: SUBDOMAIN_FORMAT },
            exclusion: { in: RESERVED_SUBDOMAINS },
            length: { minimum: 2, maximum: 63 }
end
