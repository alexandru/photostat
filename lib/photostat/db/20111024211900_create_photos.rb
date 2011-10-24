class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photostat_photos do |t|
      t.column :local_path, :string, :null => false
      t.column :md5, :string, :null => false
      t.column :visibility, :string, :null => false
      t.column :exif_dump, :text, :null => false

      t.timestamps
    end
  end
end
