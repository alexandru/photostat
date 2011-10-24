class CreateTags < ActiveRecord::Migration
  def change
    create_table :photostat_tags do |t|
      t.column :name, :string, :null => false
      t.column :photo_id, :integer, :null => false
      t.timestamps
    end

    add_index :photostat_tags, :photo_id
  end
end
