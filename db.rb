require 'sequel'

$DB ||= Sequel.connect 'jdbc:sqlite:db/development.sqlite3'
