require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

def load_list(list_id)
  list = @storage.find_list_by_id(list_id)
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif @storage.all_lists.any? { |list| list[:name] == name && list[:id] != params[:id] } # The second condition of the `any?` method block allows the user to 'Save' the edited list, even if the list's name is = to its previous name
    "The list's name must be unique."
  end
end

def error_for_todo(list_id, text)
  if !(1..100).cover? text.size
    "Todo name must be between 1 and 100 characters."
  elsif load_list(list_id)[:todos].any? { |todo| todo[:name] == text }
    "The todo's name must be unique."
  end
end

before do
  @storage = DatabasePersistence.new(logger)
end

get "/" do
  redirect "/lists"
end

# View all of the lists
get "/lists" do
  @lists = @storage.all_lists.sort_by { |list| list[:all_completed] ? 1 : 0 }
  @title = "Todo Tracker - All Lists"
  
  erb :lists, layout: :layout
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    @storage.create_new_list(list_name)
    session[:success] = "The list has been created."
    redirect "/lists/#{@storage.list_id(list_name)}"
  end
end

# Render the new list form
get "/lists/new" do
  @title = "Creating a new list..."
  erb :new_list, layout: :layout
end

# Render specific list page based on list id
get "/lists/:id" do
  list_id = params[:id]
  @list = load_list(list_id)
  @title = @list[:name]
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  list_id = params[:id]
  @list = load_list(list_id)
  @title = "Editing '#{@list[:name]}' list..."
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id/edit" do
  list_name = params[:list_name].strip
  list_id = params[:id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    redirect "/lists/#{list_id}/edit"
  else
    @storage.update_list_name(list_id, list_name)
    session[:success] = "The list has been updated."
    redirect "/lists/#{list_id}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  list_id = params[:id]
  deleted_list = @storage.delete_list(list_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "'#{deleted_list}' has been deleted."
    redirect "/lists"
  end
end

# Add a 'todo' to a todo list
post "/lists/:id/todos" do
  list_id = params[:id]
  text = params[:todo].strip

  error = error_for_todo(list_id, text)
  if error
    @list = load_list(list_id)
    session[:error] = error
    erb :list, layout: :layout
  else
    @storage.create_new_todo(list_id, text)
    session[:success] = "The todo '#{text}' was added successfully."
    redirect "/lists/#{list_id}"
  end
end

# Delete todo item
post "/lists/:id/todos/:todo_id/destroy" do
  list_id = params[:id]
  todo_id = params[:todo_id]
  deleted_item = @storage.delete_todo(list_id, todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "'#{deleted_item}' todo was removed successfully."
    redirect "/lists/#{list_id}"
  end
end

# Toggles completion status of all todos
post "/lists/:id/complete_all" do
  list_id = params[:id]
  @storage.toggle_all_todos_status(list_id)
  status = @storage.is_list_complete?(list_id)

  session[:success] = "All todos have been marked as #{status ? 'completed' : 'incomplete' }."
  redirect "/lists/#{list_id}"
end

# Toggle completion status of todo
post "/lists/:id/todos/:todo_id" do
  list_id = params[:id]
  todo_id = params[:todo_id]
  is_completed = params[:completed] == 'true'
  @storage.toggle_todo_status(list_id, todo_id, is_completed)

  session[:success] = "The todo '#{@storage.todo_name(list_id, todo_id)}' has been marked as #{is_completed ? 'completed' : 'incomplete'}. #{ @storage.list_status(list_id) ? "'#{@storage.list_name(list_id)}' is complete!" : '' }"
  redirect "/lists/#{list_id}"
end

helpers do
  # Counts number of todos completed within a list
  def todo_completion_counter(list)
    complete = 0
    list[:todos].each do |todo|
       if todo[:completed] == true
        complete += 1
       end
    end

    complete
  end

  # Returns total size of todo list
  def todos_count(list)
    list[:todos].size
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end