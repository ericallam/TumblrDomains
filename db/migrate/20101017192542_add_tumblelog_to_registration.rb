class AddTumblelogToRegistration < ActiveRecord::Migration
  def self.up
    add_column :registrations, :tumblelog, :string
  end

  def self.down
    remove_column :registrations, :tumblelog
  end
end
