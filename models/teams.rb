class Teams
  def self.db
    return @db if @db
    @db = SQLite3::Database.new("db/todo.sqlite")
    @db.results_as_hash = true
    return @db
  end

  def self.all
    return db.execute('SELECT * FROM teams')
  end

  def self.getCurrentTeam(team_id)
    db.execute("SELECT * FROM teams WHERE id = ?", team_id).first
  end

  def self.getPlayers(team_id)
    return db.execute("SELECT * FROM players WHERE team_id = ?", team_id)
  end

  def self.getTeam(team_id)
    return db.execute("SELECT * FROM teams WHERE id = ?", team_id).first
  end

  def self.getCalendarFromTeam(team_id)
    return db.execute("SELECT * FROM calendar WHERE team_id = ?", team_id)
  end
end
