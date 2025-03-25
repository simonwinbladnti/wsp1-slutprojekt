class Users
  def self.db
    return @db if @db
    @db = SQLite3::Database.new("db/todo.sqlite")
    @db.results_as_hash = true
    return @db
  end

  def self.all
    return db.execute('SELECT * FROM users')
  end

  def self.getCurrentUser(user_id)
    return db.execute("SELECT * FROM users WHERE id = ?", user_id).first
  end

  def self.getUser(username)
    return db.execute("SELECT * FROM users WHERE username = ?", username).first
  end

  def self.createUser(username, password)
    db.execute("INSERT INTO users (username, password) VALUES (?,?)", username, password)
  end

  def self.updatePassword(user_id, hashed_password)
    db.execute("UPDATE users SET password = ? WHERE id = ?", [hashed_password, user_id])
  end
end
