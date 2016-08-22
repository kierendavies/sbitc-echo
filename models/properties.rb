require 'db'

module Properties

  def self.get name
    $DB[:properties].where(name: name).first.try :[], :value
  end

  def self.set name, value
    $DB.transaction do
      $DB[:properties].where(name: name).delete
      $DB[:properties].insert(name: name, value: value)
    end
  end
end
