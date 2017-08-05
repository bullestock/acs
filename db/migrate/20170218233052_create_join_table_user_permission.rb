class CreateJoinTableUserPermission < ActiveRecord::Migration
  def change
    create_join_table :permissions, :users do |t|
      # t.index [:permission_id, :user_id]
      # t.index [:user_id, :permission_id]
    end
  end
end
