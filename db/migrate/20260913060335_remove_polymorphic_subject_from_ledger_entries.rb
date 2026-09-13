class RemovePolymorphicSubjectFromLedgerEntries < ActiveRecord::Migration[8.1]
  # Dropping the polymorphic subject rather than keeping it around
  # unused: locking a billable entry to a specific model (Proposal,
  # OutreachContact, whatever) meant a migration every time a new kind
  # of billable thing showed up. The existing free-text `description`
  # column now carries that job instead, so no schema change is needed
  # the next time what's billable changes shape.
  def change
    remove_index :ledger_entries, name: "index_ledger_entries_on_subject", if_exists: true
    remove_index :ledger_entries, name: "index_ledger_entries_on_subject_type_and_subject_id", if_exists: true
    remove_column :ledger_entries, :subject_type, :string
    remove_column :ledger_entries, :subject_id, :bigint
  end
end
