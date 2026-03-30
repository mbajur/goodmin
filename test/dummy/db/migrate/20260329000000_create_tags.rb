class CreateTags < ActiveRecord::Migration[5.0]
  def change
    create_table :tags do |t|
      t.references :comment, index: true, foreign_key: true
      t.string :name
    end
  end
end
