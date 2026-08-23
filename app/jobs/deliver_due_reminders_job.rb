# Runs on a recurring schedule (see config/recurring.yml), not enqueued
# per-tenant like a normal ApplicationJob — there's no single tenant to
# capture at enqueue time, it has to sweep all of them. So unlike other
# ApplicationJob subclasses, this one explicitly loops tenants and opens
# database tenant context (Current.tenant + the RLS GUC) once per tenant,
# rather than relying on the tenant_id captured at enqueue (there is none).
class DeliverDueRemindersJob < ApplicationJob
  def perform
    Tenant.find_each do |tenant|
      with_database_tenant_context(tenant) do
        Reminder.pending.due.find_each(&:deliver!)
      end
    end
  end
end
