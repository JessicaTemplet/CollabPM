FactoryBot.define do
  factory :shared_file do
    tenant
    file_folder { nil }
  end
end
