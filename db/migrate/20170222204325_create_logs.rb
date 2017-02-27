class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.timestamp :stamp
      t.integer :machine_id
      t.string :message

      t.timestamps null: false
    end
  end
end
