class RemoveUpdatedAtFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :updated_at, :datetime
  end
end
