class RemoveAccessToFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :access_to, :array
  end
end
