require_relative 'models/users.rb'
require_relative 'models/teams.rb'

##
# Main application class for Sports Club Management
class App < Sinatra::Base
  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  before do
    pass if request.path_info.start_with?('/login') || request.path_info == '/logout'
  
    if logged_in?
      @current_user = current_user
    else
      redirect '/login'
    end
  end

  helpers do
    def require_login
      redirect '/login' unless logged_in?
    end
  
    def require_admin
      require_login
      redirect '/teams' unless admin?
    end
  end  
  
  # Tracks failed login attempts by IP
  FAILED_LOGINS = {}
  COOLDOWN_PERIOD = 30 # seconds

  ##
  # Checks if the user is logged in
  # @return [Boolean]
  def logged_in?
    !!session[:user_id]
  end

  ##
  # Checks if current user is admin
  # @return [Boolean]
  def admin?
    current_user && current_user['username'] == 'admin'
  end

  ##
  # Fetches the current logged-in user
  # @return [Hash, nil]
  def current_user
    @current_user ||= Users.getCurrentUser(session[:user_id]) if logged_in?
  end

  ##
  # GET /login
  # Renders the login page
  get '/login' do
    erb :login
  end

  ##
  # POST /login
  # Handles login attempts with cooldown after multiple failures
  #
  # @param [String] username
  # @param [String] password
  # @return [ERB] login or redirect to /teams
  post '/login' do
    ip = request.ip
    now = Time.now
    FAILED_LOGINS[ip] ||= { count: 0, last_attempt: now }

    if FAILED_LOGINS[ip][:count] >= 2
      if (now - FAILED_LOGINS[ip][:last_attempt]) < COOLDOWN_PERIOD
        @error = "Too many failed attempts. Please wait #{(COOLDOWN_PERIOD - (now - FAILED_LOGINS[ip][:last_attempt])).ceil} seconds."
        return erb :login
      else
        FAILED_LOGINS[ip][:count] = 0
      end
    end

    username = params[:username]
    password = params[:password]
    user = Users.getUser(username)

    if user && BCrypt::Password.new(user['password']) == password
      session[:user_id] = user['id']
      FAILED_LOGINS.delete(ip)
      redirect '/teams'
    else
      FAILED_LOGINS[ip][:count] += 1
      FAILED_LOGINS[ip][:last_attempt] = now
      @error = "Invalid username or password"
      erb :login
    end
  end

  ##
  # GET /logout
  # Logs the user out and redirects to login
  get '/logout' do
    session.clear
    redirect '/login'
  end

  ##
  # GET /
  # Redirects to /login or /teams depending on login status
  get '/' do
    require_login
    redirect '/teams'
  end

  ##
  # GET /teams
  # Lists all teams
  # @return [ERB] teams
  get '/teams' do
    @teams = Teams.all
    @current_user = current_user
    erb :teams
  end

  ##
  # GET /teams/:id
  # Shows dashboard for a specific team
  # @param [Integer] id
  get '/teams/:id' do
    @current_user = current_user
    @team = Teams.getTeam(params[:id])

    if @team
      erb :team_dashboard
    else
      redirect '/teams'
    end
  end

  ##
  # GET /teams/:id/calendar
  # Shows calendar for a specific team
  get '/teams/:id/calendar' do
    @current_user = current_user
    @team = Teams.getTeam(params[:id])

    if @team
      @calendar = Teams.getCalendarFromTeam(@team['id'])
      erb :calendar
    else
      redirect '/teams'
    end
  end

  ##
  # GET /teams/:id/members
  # Lists members in a team
  get '/teams/:id/members' do
    @current_user = current_user
    @team = Teams.getTeam(params[:id])

    if @team
      @players = Teams.getPlayers(@team['id'])
      erb :team_members
    else
      redirect '/teams'
    end
  end

  ##
  # GET /admin/teams/create
  # Form for creating new team (admin only)
  get '/admin/teams/create' do
    require_login
    require_admin
    erb :add_team
  end

  ##
  # POST /teams
  # Creates a new team (admin only)
  post '/teams' do
    require_login
    require_admin

    name = params[:name]
    label = params[:label]
    Teams.create(name, label)

    redirect '/teams'
  end

  ##
  # GET /teams/:id/add_member
  # Form to add member to team (admin only)
  get '/teams/:id/add_member' do
    require_login
    require_admin

    @team = Teams.getTeam(params[:id])
    erb :add_member
  end

  ##
  # POST /teams/:id/members
  # Adds a player to the team (admin only)
  post '/teams/:id/members' do
    require_login
    require_admin

    team_id = params[:id]
    name = params[:name]
    role = params[:role]

    Teams.add_player_to_team(team_id, name, role)

    redirect "/teams/#{team_id}/members"
  end

  ##
  # GET /teams/:id/add_event
  # Form to add event to team calendar (admin only)
  get '/teams/:id/add_event' do
    require_login
    require_admin

    @team = Teams.getTeam(params[:id])
    erb :add_event
  end

  ##
  # POST /teams/:id/calendar
  # Adds a new calendar event (admin only)
  post '/teams/:id/calendar' do
    require_login
    require_admin

    team_id = params[:id]
    date = params[:event_date]
    time = params[:event_time]
    location = params[:event_location]

    Teams.add_event_to_team(team_id, date, time, location)

    redirect "/teams/#{team_id}/calendar"
  end

  ##
  # POST /teams/:team_id/players/:player_id/delete
  # Removes a player from team and deletes the player (admin only)
  post '/teams/:team_id/players/:player_id/delete' do
    require_login
    require_admin

    team_id = params[:team_id]
    player_id = params[:player_id]

    Teams.remove_player_from_team(team_id, player_id)
    Teams.delete_player(player_id)

    redirect "/teams/#{team_id}/members"
  end

  ##
  # POST /teams/:id/delete
  # Deletes a team and all associated data (admin only)
  post '/teams/:id/delete' do
    require_login
    require_admin

    team_id = params[:id]

    Teams.remove_team_events(team_id)
    Teams.remove_team_players(team_id)
    Teams.delete_team(team_id)

    redirect '/teams'
  end

  ##
  # GET /profile
  # Shows the profile page for current user
  get '/profile' do
    if current_user
      @user = current_user
      erb :profile
    else
      redirect '/login'
    end
  end

  ##
  # POST /change_password
  # Allows current user to change their password
  #
  # @param [String] current_password
  # @param [String] new_password
  # @param [String] confirm_password
  post '/change_password' do
    current_password = params[:current_password]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]

    user = current_user

    if BCrypt::Password.new(user['password']) == current_password
      if new_password == confirm_password
        hashed_new_password = BCrypt::Password.create(new_password)
        Users.updatePassword(user['id'], hashed_new_password)
        @message = "Password successfully updated."
      else
        @error = "New passwords do not match."
      end
    else
      @error = "Current password is incorrect."
    end

    @user = current_user
    erb :profile
  end

  ##
  # GET /admin
  # Admin dashboard with list of users (admin only)
  get '/admin' do
    require_admin
    @users = Users.all
    erb :admin
  end
  

  ##
  # GET /admin/users/create
  # Form for creating new user (admin only)
  get '/admin/users/create' do
  require_login
    require_admin

    erb :create_user
  end

  ##
  # POST /admin/users
  # Creates a new user (admin only)
  post '/admin/users' do
    require_login
    require_admin
    
    username = params[:username]
    password = params[:password]
    password_hashed = BCrypt::Password.create(password)

    Users.createUser(username, password_hashed)

    redirect '/admin'
  end
end
