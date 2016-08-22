Sequel.migration do
  change do
    create_table :agenda_items do
      String :agenda_item, text: true
    end
    create_table :participants do
      String :participant
    end
    create_table :actions do
      String :action
    end
    create_table :notes do
      String :note, text: true
    end
    create_table :votes do
      foreign_key :motion_id, :motions
      TrueClass :value
    end
    create_table :motions do
      primary_key :id
      String :motion, text: true
    end
  end
end
