class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :fl_id
      t.integer :member_id
      t.string :first_name
      t.string :last_name
      t.string :display_name
      t.boolean :active
      t.string :card_id
      t.text :access_to, array: true, default: []
      t.boolean :can_login
      t.boolean :can_provision
      t.boolean :can_deprovision

      t.timestamps null: false
    end
  end
end
