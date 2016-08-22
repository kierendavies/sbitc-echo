Sequel.migration do
  change do
    create_table :session do
      String :id
      String :state
    end
  end
end
