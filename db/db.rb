# db.rb
require 'sqlite3'

module DB
  def self.connection
    return @db if @db

    @db = SQLite3::Database.new("db/todo.sqlite")
    @db.results_as_hash = true
    @db
  end
end
