Sequel.migration do
  up do
    create_table :photos do
      primary_key :id
      
      String :uid, :null => false
      String :type, :null => false

      String :local_path, :null => false
      String :visibility, :null => false
      DateTime :created_at, :null => false      

      String :md5, :null => true

      index :uid, :unique => true
      index :local_path
      index :type
      index :md5
    end

    create_table :tags do
      primary_key :id
      String :name, :null => false
      String :photo_id, :null => false      

      index [:photo_id, :name], :unique => true
    end
  end

  down do
    drop_column :photos, :tags
  end
end
