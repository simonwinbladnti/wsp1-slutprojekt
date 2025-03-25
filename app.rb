require_relative 'models/users.rb'
require_relative 'models/teams.rb'
   class App < Sinatra::Base

        def db
            return @db if @db

            @db = SQLite3::Database.new("db/todo.sqlite")
            @db.results_as_hash = true

            return @db
        end

        configure do
            enable :sessions
            set :session_secret, SecureRandom.hex(64)
        end

        def logged_in?
            session[:user_id]
        end

        def current_team?
            if session[:team_id]
                Teams.getCurrentTeam(session[:team_id])
            end
        end
        

        def admin?
            current_user? && current_user['username'] == 'admin'
        end

        def current_user?
            @current_user ||= Users.getCurrentUser(session[:user_id]) if logged_in?
            print(@current_user)
            return @current_user
        end

        get '/login' do
            erb :login
        end

        get '/index' do
            @teams = db.execute("SELECT * FROM teams")
            
            @current_team = current_team?
            @current_user = current_user?
        
            erb :index
        end
        

        post '/select_team' do
            team_id = params[:team_id]
        
            session[:team_id] = team_id
        
            redirect '/index'
        end

        get '/calendar' do
            @current_user = current_user?
            team_id = session[:team_id]
            if team_id
                @team = Teams.getTeam(team_id)
                @current_team = current_team?
        
                @calendar = Teams.getCalendarFromTeam(team_id)
        
                erb :calendar
            else
                redirect '/index'
            end
        end
        
        
        
        
        get '/team' do
            @current_user = current_user?
            @current_team = current_team? 
            @team = current_team?

            if @team
            @players = Teams.getPlayers(@team['id'])
            else
            @players = [] 
            end
        
            erb :team
        end

        get '/profile' do
            if current_user?
                @user = current_user?
                erb :profile
            else
                redirect '/login'
            end
        end
        
        post '/change_password' do
            current_password = params[:current_password]
            new_password = params[:new_password]
            confirm_password = params[:confirm_password]
          
            user = current_user?
          
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
          
            @user = current_user?
            erb :profile
          end
          

        post '/login' do
            username = params[:username]
            password = params[:password]

            user = Users.getUser(username)

            if user && BCrypt::Password.new(user['password']) == password
                session[:user_id] = user['id']
                redirect '/index'
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
            @current_user = current_user?
            redirect('/login') unless logged_in?
            redirect('/index')
        end

        get '/admin' do
            redirect('/login') unless logged_in?
            redirect('/index') unless admin? 

            @users = Users.All()
            erb(:"admin")
        end 

        get '/admin/users/create' do
            redirect('/login') unless logged_in?
            redirect('/index') unless admin?

            erb(:"create_user")
        end

        post '/admin/users' do
            redirect('/login') unless logged_in?
            redirect('/index') unless admin?

            username = params[:username]
            password = params[:password]

            password_hashed = BCrypt::Password.create(password)

            Users.createUser(username, password_hashed)

            redirect '/admin'
        end

    end
