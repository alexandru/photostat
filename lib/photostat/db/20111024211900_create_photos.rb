class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.column :local_path, :string, :null => false
      t.timestamps
    end
  end
end
