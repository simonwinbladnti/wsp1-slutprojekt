require_relative 'models/users.rb'
require_relative 'models/teams.rb'

class App < Sinatra::Base
  configure do
    enable :sessions
    set :session_secret, SecureRandom.hex(64)
  end

  def logged_in?
    !!session[:user_id]
  end

  def admin?
    current_user && current_user['username'] == 'admin'
  end

  def current_user
    @current_user ||= Users.getCurrentUser(session[:user_id]) if logged_in?
  end

  get '/login' do
    erb :login
  end

  post '/login' do
    username = params[:username]
    password = params[:password]
    user = Users.getUser(username)

    if user && BCrypt::Password.new(user['password']) == password
      session[:user_id] = user['id']
      redirect '/teams'
    else
      @error = "Invalid username or password"
      erb :login
    end
  end

  get '/logout' do
    session.clear
    redirect '/login'
  end

  get '/' do
    redirect '/login' unless logged_in?
    redirect '/teams'
  end

  get '/teams' do
    @teams = Teams.all
    @current_user = current_user
    erb :teams
  end

  get '/teams/:id' do
    @current_user = current_user
    @team = Teams.getTeam(params[:id])

    if @team
      erb :team_dashboard
    else
      redirect '/teams'
    end
  end

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

  get '/teams/:id/members' do
    @current_user = current_user
    @team = Teams.getTeam(params[:id])

    if @team
      @players = Teams.getPlayers(@team['id'])  # Get players using the team_players junction
      erb :team_members
    else
      redirect '/teams'
    end
  end

  get '/admin/teams/create' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    erb :add_team
  end

  post '/teams' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    name = params[:name]
    label = params[:label]
    Teams.create(name, label)

    redirect '/teams'
  end

  get '/teams/:id/add_member' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    @team = Teams.getTeam(params[:id])
    erb :add_member
  end

  post '/teams/:id/members' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?
  
    team_id = params[:id]
    name = params[:name]
    role = params[:role]
  
    Teams.add_player_to_team(team_id, name, role)
  
    redirect "/teams/#{team_id}/members"
  end
  

  get '/teams/:id/add_event' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    @team = Teams.getTeam(params[:id])
    erb :add_event
  end

  post '/teams/:id/calendar' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    team_id = params[:id]
    date = params[:event_date]
    time = params[:event_time]
    location = params[:event_location]

    Teams.add_event_to_team(team_id, date, time, location)

    redirect "/teams/#{team_id}/calendar"
  end

    post '/teams/:team_id/players/:player_id/delete' do
        redirect('/login') unless logged_in?
        redirect('/teams') unless admin?

        team_id = params[:team_id]
        player_id = params[:player_id]

        Teams.remove_player_from_team(team_id, player_id)

        Teams.delete_player(player_id)

        redirect "/teams/#{team_id}/members"
    end

    post '/teams/:id/delete' do
        redirect('/login') unless logged_in?
        redirect('/teams') unless admin?
    
        team_id = params[:id]
    
        Teams.remove_team_events(team_id)
    
        Teams.remove_team_players(team_id)
    
        Teams.delete_team(team_id)
    
        redirect '/teams'
    end
  
  

  get '/profile' do
    if current_user
      @user = current_user
      erb :profile
    else
      redirect '/login'
    end
  end

  post '/change_password' do
    current_password = params[:current_password]
    new_password = params[:new_password]
    confirm_password = params[:confirm_password]

    user = current_user

    if BCrypt::Password.new(user['password']) == current_password
      if new_password == confirm_password
        hashed_new_password = BCrypt::Password.create(new_password)
        Users.updatePassword(user['id'], hashed_new_password)  # Use Users model to update password
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

  get '/admin' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    @users = Users.All()
    erb :admin
  end

  get '/admin/users/create' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    erb :create_user
  end

  post '/admin/users' do
    redirect('/login') unless logged_in?
    redirect('/teams') unless admin?

    username = params[:username]
    password = params[:password]
    password_hashed = BCrypt::Password.create(password)

    Users.createUser(username, password_hashed)

    redirect '/admin'
  end
end
