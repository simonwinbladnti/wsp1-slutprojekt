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
            db.execute("SELECT * FROM teams WHERE id = ?", session[:team_id]).first
            end
        end
        

        def admin?
            current_user && current_user['username'] == 'admin'
        end

        def current_user
            @current_user ||= db.execute("SELECT * FROM users WHERE id = ?", session[:user_id]).first if logged_in?
        end

        get '/login' do
            erb :login
        end

        get '/index' do
            @teams = db.execute("SELECT * FROM teams")
            
            @current_team = current_team?
        
            erb :index
        end
        

        post '/select_team' do
            team_id = params[:team_id]
        
            session[:team_id] = team_id
        
            redirect '/index'
        end

        get '/calendar' do
            team_id = session[:team_id]
            if team_id
                @team = db.execute("SELECT * FROM teams WHERE id = ?", team_id).first
                @current_team = current_team?
        
                @calendar = db.execute("SELECT * FROM calendar WHERE team_id = ?", team_id)
        
                erb :calendar
            else
                redirect '/index'
            end
        end
        
        
        
        
        get '/team' do
            @current_team = current_team? 
            @team = current_team?

            if @team
            @players = db.execute("SELECT * FROM players WHERE team_id = ?", @team['id'])
            else
            @players = [] 
            end
        
            erb :team
        end
        
        
        post '/login' do
            username = params[:username]
            password = params[:password]

            user = db.execute("SELECT * FROM users WHERE username = ?", username).first

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
            redirect('/login') unless logged_in?
            redirect('/index')
        end

        get '/admin' do
            redirect('/login') unless logged_in?
            redirect('/index') unless admin? 

            @users = db.execute('SELECT * FROM users')
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

            db.execute('INSERT INTO users (username, password) VALUES (?, ?)', [username, password_hashed])

            redirect '/admin'
        end

    end
