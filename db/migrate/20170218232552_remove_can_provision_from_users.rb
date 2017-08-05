class RemoveCanProvisionFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :can_provision, :bool
  end
end
