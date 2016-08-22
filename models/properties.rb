require 'db'

module Properties

  def self.get name
    $DB[:properties].where(name: name).first.try :[], :value
  end

  def self.set name, value
    $DB[:properties].insert_conflict(:update).insert(name: name, value: value)
  end
end
