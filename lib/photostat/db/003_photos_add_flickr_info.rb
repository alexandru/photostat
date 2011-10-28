Sequel.migration do
  change do
    alter_table :photos do
      add_column :has_flickr_upload, FalseClass, :default => false, :null => false
    end
  end
end
