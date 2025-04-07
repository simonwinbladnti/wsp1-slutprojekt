require_relative '../db/db'

class Teams
  def self.db
    DB.connection
  end

  def self.all
    return db.execute('SELECT * FROM teams')
  end

  def self.getTeam(team_id)
    db.execute("SELECT * FROM teams WHERE id = ?", team_id).first
  end

  def self.create(name, label)
    db.execute("INSERT INTO teams (name, label) VALUES (?, ?)", [name, label])
  end

  def self.add_player_to_team(team_id, name, role)

    db.execute('INSERT INTO players (name, role) VALUES (?, ?)', [name, role])
    player_id = db.last_insert_row_id 

    db.execute("INSERT INTO team_players (team_id, player_id) VALUES (?, ?)", [team_id, player_id])
  end  

  def self.add_event_to_team(team_id, date, time, location)
    db.execute("INSERT INTO calendar (team_id, event_date, event_time, event_location) VALUES (?, ?, ?, ?)", [team_id, date, time, location])
  end

  def self.getPlayers(team_id)
    db.execute('SELECT players.* FROM players
               JOIN team_players ON players.id = team_players.player_id
               WHERE team_players.team_id = ?', team_id)
  end

  def self.getCalendarFromTeam(team_id)
    db.execute("SELECT * FROM calendar WHERE team_id = ?", team_id)
  end

  def self.remove_player_from_team(team_id, player_id)
    db.execute("DELETE FROM team_players WHERE team_id = ? AND player_id = ?", [team_id, player_id])
  end

  # Delete a player from the players table
  def self.delete_player(player_id)
    db.execute("DELETE FROM players WHERE id = ?", [player_id])
  end

  def self.remove_team_events(team_id)
    db.execute("DELETE FROM calendar WHERE team_id = ?", [team_id])
  end

  def self.remove_team_players(team_id)
    db.execute("DELETE FROM team_players WHERE team_id = ?", [team_id])
  end

  def self.delete_team(team_id)
    db.execute("DELETE FROM teams WHERE id = ?", [team_id])
  end
end
