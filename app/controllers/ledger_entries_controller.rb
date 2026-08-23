class LedgerEntriesController < ApplicationController
  # Append-only ledger: no edit/update/destroy actions here on purpose —
  # LedgerEntry#readonly? backs this at the model layer too.
  def index
    @entries = Current.tenant.ledger_entries.order(created_at: :desc)
    @balance_cents = @entries.sum { |e| e.entry_type == "payment" ? -e.amount_cents : e.amount_cents }
  end

  def create
    @entry = Current.tenant.ledger_entries.new(entry_params)
    @entry.created_by = Current.user

    if @entry.save
      redirect_to ledger_entries_path, notice: "Entry recorded."
    else
      # nosemgrep: ruby.rails.security.audit.xss.avoid-redirect.avoid-redirect
      # Destination is the fixed ledger_entries_path; only the alert text
      # is dynamic (validation error messages).
      redirect_to ledger_entries_path, alert: @entry.errors.full_messages.to_sentence
    end
  end

  private

  def entry_params
    params.require(:ledger_entry).permit(:method, :entry_type, :amount_cents, :description, :subject_type, :subject_id)
  end
end
