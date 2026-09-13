FactoryBot.define do
  factory :file_folder do
    tenant
    sequence(:name) { |n| "Folder #{n}" }
  end
end
