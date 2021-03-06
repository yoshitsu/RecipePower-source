class CreateEventNotices < ActiveRecord::Migration
  def change
    create_table :event_notices, :force => true do |t|
      t.integer :event_id
      t.integer :user_id
      t.boolean :read, default: false

      t.timestamps
    end 
  end
end
