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
    db.execute('DROP TABLE IF EXISTS players')
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
      label VARCHAR(255) NOT NULL
    )')
    
    db.execute('CREATE TABLE calendar (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      team_id INTEGER NOT NULL,
      event_date DATE NOT NULL,
      event_time TIME NOT NULL,
      event_location TEXT,
      FOREIGN KEY (team_id) REFERENCES teams(id)
    )')

    db.execute('CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      team_id INTEGER NOT NULL,
      FOREIGN KEY (team_id) REFERENCES teams(id)
    )')
  end

  def self.populate_tables
    # Populate users
    password_hashed = BCrypt::Password.create("admin")
    p "Storing hashed version of password to db. Clear text never saved. #{password_hashed}"
    db.execute('INSERT INTO users (username, password) VALUES (?, ?)', ["admin", password_hashed])
  
    # Teams data
    teams = [
      { name: "Warriors", label: "WRS" },
      { name: "Lions", label: "LNS" },
      { name: "Tigers", label: "TGR" },
      { name: "Eagles", label: "EGL" },
      { name: "Sharks", label: "SHK" }
    ]
  
    teams.each do |team|
      db.execute('INSERT INTO teams (name, label) VALUES (?, ?)', [team[:name], team[:label]])
    end
    team_ids = db.execute('SELECT id, name FROM teams').to_h { |row| [row['name'], row['id']] }

    players = [
      { name: "Player1", role: "Forward", team: "Warriors" },
      { name: "Player2", role: "Defender", team: "Warriors" },
      { name: "Player3", role: "Forward", team: "Lions" },
      { name: "Player4", role: "Goalkeeper", team: "Lions" },
      { name: "Player5", role: "Midfielder", team: "Tigers" },
      { name: "Player6", role: "Forward", team: "Tigers" },
      { name: "Player7", role: "Defender", team: "Eagles" },
      { name: "Player8", role: "Goalkeeper", team: "Eagles" },
      { name: "Player9", role: "Forward", team: "Sharks" },
      { name: "Player10", role: "Defender", team: "Sharks" }
    ]
  
    players.each do |player|
      team_id = team_ids[player[:team]]
      db.execute('INSERT INTO players (name, role, team_id) VALUES (?, ?, ?)', [player[:name], player[:role], team_id])
    end

    # Calendar data for events
    calendar = [
      { team_name: "Warriors", date: "2025-02-17", time: "10:00", location: "Stadium" },
      { team_name: "Warriors", date: "2025-03-01", time: "15:00", location: "Field" },
      { team_name: "Lions", date: "2025-03-05", time: "12:00", location: "Arena" },
      { team_name: "Lions", date: "2025-03-12", time: "14:00", location: "Ground" },
      { team_name: "Tigers", date: "2025-04-01", time: "09:00", location: "Park" },
      { team_name: "Tigers", date: "2025-04-15", time: "16:00", location: "Hall" },
      { team_name: "Eagles", date: "2025-05-10", time: "11:00", location: "Stadium" },
      { team_name: "Eagles", date: "2025-06-01", time: "18:00", location: "Ground" },
      { team_name: "Sharks", date: "2025-06-15", time: "17:00", location: "Sea Arena" },
      { team_name: "Sharks", date: "2025-07-01", time: "19:00", location: "Water Park" }
    ]
  
    calendar.each do |event|
      team_id = team_ids[event[:team_name]]
      db.execute('INSERT INTO calendar (team_id, event_date, event_time, event_location) VALUES (?, ?, ?, ?)', 
                 [team_id, event[:date], event[:time], event[:location]])
    end

    p "Database successfully populated with users, teams, players, and events."
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
