class AddTransactionIdToRegistrations < ActiveRecord::Migration
  def self.up
    add_column :registrations, :transaction_id, :string
  end

  def self.down

    remove_column :registrations, :transaction_id
  end
end
