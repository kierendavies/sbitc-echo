Sequel.migration do
  change do
    create_table :properties do
      String :name
      String :value
    end
  end
end
