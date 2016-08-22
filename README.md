# sbitc-echo

You will need `ffmpeg` installed for the app to run correctly.

## Running

    jruby -S bundle install
    jruby -S bundle exec sequel -m db_migrations jdbc:sqlite:db/development.sqlite3
    jruby app.rb

Visit http://localhost:4567/
