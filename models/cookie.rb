require 'db'

module Cookie
  def self.get
    $DB[:cookie].first.try :[], :cookie
  end

  def self.set cookie
    $DB.transaction do
      $DB[:cookie].delete
      $DB[:cookie].insert cookie: cookie
    end
  end
end
