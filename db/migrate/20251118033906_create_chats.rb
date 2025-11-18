class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.timestamps
      t.references :story, null: false, foreign_key: true

    end
  end
end
