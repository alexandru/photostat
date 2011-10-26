Sequel.migration do
  change do
    add_index :photos, :created_at
  end
end
