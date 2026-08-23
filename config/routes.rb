Rails.application.routes.draw do
  no_tenant_subdomain = ->(req) { req.subdomain.blank? || req.subdomain == "www" }
  tenant_subdomain    = ->(req) { req.subdomain.present? && req.subdomain != "www" }

  # --- Marketing / no-tenant routes (bare domain, e.g. example.com, www.) ---
  constraints(no_tenant_subdomain) do
    root to: "marketing#index", as: :marketing_root
    get "pricing", to: "marketing#pricing"
  end

  # --- Tenant app routes (any other subdomain, e.g. acme.example.com) ---
  constraints(tenant_subdomain) do
    root to: "dashboard#index", as: :tenant_root

    resource :session, only: [ :new, :create, :destroy ]
    resource :registration, only: [ :new, :create ]
    resource :password, only: [ :new, :create, :edit, :update ], controller: "passwords"

    resources :invites, only: [ :index, :new, :create ]
    post "invites/forward", to: "invites/forwards#create", as: :forward_invite

    get "dashboard", to: "dashboard#index"

    resources :documents, only: [ :index, :show, :new, :create ]
    resources :folders, only: [ :create ]
    resources :proposals
    resources :events, only: [ :index, :create, :destroy ]
    resources :files, only: [ :index, :create, :destroy ]
    resources :ledger_entries, only: [ :index, :create ]
    resources :project_info_items, only: [ :index, :create, :destroy ]
    resources :outreach_contacts, only: [ :index, :create, :update ]
    resources :reminders, only: [ :index, :create ]
    resources :messages, only: [ :index, :create ]
  end

  # --- Webhooks (no subdomain / not tenant-scoped) ---
  namespace :webhooks do
    post "lemon_squeezy", to: "lemon_squeezy#create"
  end

  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check
end
