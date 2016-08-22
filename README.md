# sbitc-echo

## Running

    jruby -S bundle install
    jruby -S bundle exec sequel -m db_migrations jdbc:sqlite:db/development.sqlite3
    ruby app.rb

Visit http://localhost:4567/
