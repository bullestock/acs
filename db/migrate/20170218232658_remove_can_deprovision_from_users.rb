class RemoveCanDeprovisionFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :can_deprovision, :bool
  end
end
