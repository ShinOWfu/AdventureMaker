class CreateStories < ActiveRecord::Migration[7.1]
  def change
    create_table :stories do |t|
      t.string :protagonist_name
      t.string :protagonist_description
      t.string :genre
      t.string :topic
      t.text :assessment
      t.text :system_prompt
      t.references :user, null: false, foreign_key: true


      t.timestamps
    end
  end
end
