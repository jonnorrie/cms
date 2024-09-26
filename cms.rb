require "sinatra"
require "sinatra/reloader"
require "redcarpet" #Used to render Markdown text into HTML

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
  
end

root = File.expand_path("..", __FILE__)
# Returns a string of the directory
# in reference to the file we are in.



# Displays the index of files
get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    # Dir.glob returns an array of all paths directing to the files
    # in the given directory,
    # in this case the directory of our current file,
    # and then goes into the `data` directory as well
    File.basename(path)
    # Returns just the file name of a given path.
    # `map` is putting the names of the files into another array
  end
  
  erb :index
end

#  Displays the selected file
get "/:filename" do
  # the colon is used in sanatra routes to indicate that value
  # needs to be passed to the params hash
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  
  if @files.include?(params[:filename])
    file_path = root + "/data/" + params[:filename]
     # `file_path` is just a string of the file path.
      # params is a hash given to us through sinatra.
      # when we type a URL with `:filename` being the name of a file,
      # `:filename` becomes the key, and the file in the URL is the value.
      # This allows us to dynamically handle the route without creating
      # a route for every file
  
    if File.extname(file_path) == ".md"
      #  if the file type is `.md` we render it in markdown
    
      file_text = File.read(file_path)
    
      render_markdown(file_text)
    else

      headers["Content-Type"] = "text/plain"
      # This sets the content type header of the request 
      # to just plain text.
      
      File.read(file_path)
      # reads the `File.read` method with the file path passed in.
    end
  else
    session[:message] = "#{params[:filename]} does not exist"
    
    redirect "/"
  end
  
end