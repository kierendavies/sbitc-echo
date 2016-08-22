Sequel.migration do
  change do
    create_table :properties do
      primary_key :name, auto_increment: false
      String :value
    end
  end
end
