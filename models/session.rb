require 'db'

module Session
  def self.get
    $DB[:session].first || {}
  end

  def self.add id, state
    $DB.transaction do
      $DB[:session].delete
      $DB[:session].insert id: id, state: state
    end
  end
end
