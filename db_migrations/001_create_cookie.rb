Sequel.migration do
  change do
    create_table :cookie do
      String :cookie, text: true
    end
  end
end
