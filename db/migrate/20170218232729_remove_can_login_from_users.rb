class RemoveCanLoginFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :can_login, :bool
  end
end
