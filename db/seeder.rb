require 'sqlite3'
require 'bcrypt'


class Seeder
  
  def self.seed!
    drop_tables
    create_tables
    populate_tables
  end

  def self.drop_tables
    db.execute('DROP TABLE IF EXISTS users')
    db.execute('DROP TABLE IF EXISTS teams')
    db.execute('DROP TABLE IF EXISTS calendar')
  end

  def self.create_tables
    db.execute('CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password VARCHAR(255) NOT NULL
    )')
    db.execute('CREATE TABLE teams (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      label VARCHAR(255) NOT NULL,
      players VARCHAR(255) NOT NULL,
      calendar TEXT NOT NULL
    )')
    db.execute('CREATE TABLE calendar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      team_id INTEGER NOT NULL,
      event_date DATE NOT NULL,
      event_time TIME NOT NULL,
      event_location TEXT,
      FOREIGN KEY (team_id) REFERENCES teams(id)
    )')
  end

  def self.populate_tables
    password_hashed = BCrypt::Password.create("admin")
    p "Storing hashed version of password to db. Clear text never saved. #{password_hashed}"
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ["admin", password_hashed])
  
    teams = [
      { name: "Warriors", label: "WRS", players: "Player1, Player2", calendar: {
        "event1" => {"date" => "2025-02-17", "time" => "10:00", "location" => "Stadium"},
        "event2" => {"date" => "2025-03-01", "time" => "15:00", "location" => "Field"}
      }},
      { name: "Lions", label: "LNS", players: "Player3, Player4", calendar: {
        "event1" => {"date" => "2025-03-05", "time" => "12:00", "location" => "Arena"},
        "event2" => {"date" => "2025-03-12", "time" => "14:00", "location" => "Ground"}
      }},
      { name: "Tigers", label: "TGR", players: "Player5, Player6", calendar: {
        "event1" => {"date" => "2025-04-01", "time" => "09:00", "location" => "Park"},
        "event2" => {"date" => "2025-04-15", "time" => "16:00", "location" => "Hall"}
      }},
      { name: "Eagles", label: "EGL", players: "Player7, Player8", calendar: {
        "event1" => {"date" => "2025-05-10", "time" => "11:00", "location" => "Stadium"},
        "event2" => {"date" => "2025-06-01", "time" => "18:00", "location" => "Ground"}
      }},
      { name: "Sharks", label: "SHK", players: "Player9, Player10", calendar: {
        "event1" => {"date" => "2025-06-15", "time" => "17:00", "location" => "Sea Arena"},
        "event2" => {"date" => "2025-07-01", "time" => "19:00", "location" => "Water Park"}
      }}
    ]
  
    teams.each do |team|
      calendar_json = team[:calendar].to_json
      db.execute('INSERT INTO teams (name, label, players, calendar) VALUES (?, ?, ?, ?)',
                 [team[:name], team[:label], team[:players], calendar_json])
    end
  
    p "Teams have been successfully populated into the database."
  end
  

  private
  def self.db
    return @db if @db
    @db = SQLite3::Database.new('db/todo.sqlite')
    @db.results_as_hash = true
    @db
  end
end


Seeder.seed!