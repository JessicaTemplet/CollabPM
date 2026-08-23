FactoryBot.define do
  factory :folder do
    tenant
    sequence(:name) { |n| "Folder #{n}" }
  end
end
