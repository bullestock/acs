class RemoveCreatedAtFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :created_at, :datetime
  end
end
