FactoryBot.define do
  factory :tag do
    tenant
    sequence(:name) { |n| "tag#{n}" }
  end
end
