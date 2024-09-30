require "sinatra"
require "sinatra/reloader"
require "redcarpet" #Used to render Markdown text into HTML
require "yaml"
require "bcrypt"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do
  
  def render_markdown(text)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    # This is a new instance of Redcarpet
    markdown.render(text)
  end
  
  def load_file_content(path)
    content = File.read(path)
    # just displays text of given file
    # => File.read("/home/ec2-user/environment/CMS/data/about.md")
    
    case File.extname(path)
      # returns the extension of a file
      # => ".md"
    when ".txt"
      headers["Content-Type"] = "text/plain"
      content
    when ".md"
      erb render_markdown(content)
    end
          
  end
  
  def valid_credentials?(username, password)
    credentials = YAML.load_file(yaml_path)
    
    if credentials.key?(username)
    
      encrypted_password = BCrypt::Password.create(credentials[username])
      encrypted_password == password
    else
      false
    end
  end
  
  def signin_status
    session[:signin_status]
  end
  
  def restricted?
    if signin_status != true
      session[:message] = "You must be signed in to do that."
      redirect "/"
    end
  end
  
  def yaml_path
    File.expand_path("../users.yml", __FILE__)
  end
  
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
      # "/home/ec2-user/environment/CMS/test/data"
  else
    File.expand_path("../data", __FILE__)
      # =>"/home/ec2-user/environment/CMS/data"
  end
end


# root = File.expand_path("..", __FILE__)
# Returns a string of the directory
# in reference to the file we are in.

# -----------------------------------------------------------

# Displays the index of files
get "/" do
  
  pattern = File.join(data_path, "*")
  # => "/home/ec2-user/environment/CMS/data/*"
  #File.join returns a string with the second argument appended between a `/`
  
  
  @files = Dir.glob(pattern).map do |path|
    # => ["/home/ec2-user/environment/CMS/data/about.md], ["/home/ec2-user/environment/CMS/data/changes.txt"], [""/home/ec2-user/environment/CMS/data/changes.txt"]
    # Dir.glob returns an array of all paths directing to the files
    # in the given directory,
    # in this case the directory of our current file,
    # and then goes into the `data` directory as well
    File.basename(path)
    # =>["about.md"], ["changes.txt"], ["history.txt"]
    # Returns just the file name of a given path.
    # `map` is putting the names of the files into another array
  end

  erb :index, layout: :layout
end

# -----------------------------------------------------------

# displays the file edit page
get "/:filename/edit" do
  restricted?
  file_path =  File.join(data_path, params[:filename])
  
  @filename = params[:filename]
  @content = File.read(file_path)
  
  erb :edit, layout: :layout
end

# -----------------------------------------------------------
# displays the new file page
get "/new" do
  restricted?
  erb :new, layout: :layout
end

# -----------------------------------------------------------
# creates a new file
post "/create" do
  restricted?
  
  if params[:filename].size == 0
   
    session[:message] = "A name is required"
    
    redirect "/new"
    
  else
    file_path = File.join(data_path, params[:filename].to_s)
    # => "/home/ec2-user/environment/CMS/data/new_doc.txt"
    
    File.write(file_path, "")
    # Creates a file at the given directory, with the contents of the second argument
    
    session[:message] = "'#{params[:filename]}' has been created."
    
    redirect "/"
  end
end

# -----------------------------------------------------------

#  Displays the selected file
get "/:filename" do
  # the colon is used in sanatra routes to indicate that value
  # needs to be passed to the params hash
  # about.md
  
  requested_file = params[:filename]
  # about.md
  
  file_path = File.join(data_path, requested_file)
  # "/home/ec2-user/environment/CMS/data" + "about.md"
  # => "/home/ec2-user/environment/CMS/data/about.md"
  
  
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist"
    redirect "/"
  end
end

# -----------------------------------------------------------

# submission for file edits
post "/:filename/update" do
  restricted?
  
  file_path = File.join(data_path, params[:filename])
  
  File.write(file_path, params[:content])
  
  session[:message] = "'#{params[:filename]}' has been updated."
  
  redirect "/"

end

# -----------------------------------------------------------

# deletes the file
post "/:filename/delete_file" do
  
  restricted?
  
    path_to_given_file = File.join(data_path, params[:filename])
    
    File.delete(path_to_given_file)
    
    session[:message] = "'#{params[:filename]}' has been deleted."
    
    redirect "/"
end

# -----------------------------------------------------------

# sign in page
get "/users/signin" do
  erb :signin, layout: :layout
end

# -----------------------------------------------------------

# signs the user in
post "/users/signin" do
  
  if valid_credentials?(params[:username], params[:password])
    session[:username ] = params[:username]
    session[:signin_status] = true
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Username or Password"
    erb :signin, layout: :layout
  end
  
end


#signs the user out
post "/users/signout" do
  
  session[:signin_status] = false
  session[:message] = "You have been signed out"
  
  redirect "/"
end