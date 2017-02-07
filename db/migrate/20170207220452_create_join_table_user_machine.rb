class CreateJoinTableUserMachine < ActiveRecord::Migration
  def change
    create_join_table :machines, :users do |t|
      # t.index [:machine_id, :user_id]
      # t.index [:user_id, :machine_id]
    end
  end
end
