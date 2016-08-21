require 'sequel'

$DB ||= Sequel.connect 'sqlite://db/development.db'
