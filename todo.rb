require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View all of the lists
get "/lists" do
  @lists = session[:lists].sort_by { |list| list[:all_completed] ? 1 : 0 }
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
    list = { name: list_name, id: SecureRandom.hex(2), todos: [], all_completed: false }
    session[:lists] << list
    session[:success] = "The list has been created."
    redirect "/lists/#{list[:id]}"
  end
end

# Render the new list form
get "/lists/new" do
  @title = "Creating a new list..."
  erb :new_list, layout: :layout
end

get "/lists/:id" do
  @list = find_list_by_id(params[:id])
  @title = @list[:name]
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  @list = find_list_by_id(params[:id])
  @title = "Editing '#{@list[:name]}' list..."
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id/edit" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    redirect "/lists/#{params[:id]}/edit"
  else
    session[:lists].map! do |list|
      if list[:id] == params[:id]
        list[:name] = list_name
      end
    list
    end
    session[:success] = "The list has been updated."
    redirect "/lists/#{params[:id]}"
  end
end

# Delete a todo list
post "/lists/:id/destroy" do
  list = find_list_by_id(params[:id])

  session[:lists].delete(list)
  session[:success] = "'#{list[:name]}' has been deleted."
  redirect "/lists"
end

# Add a 'todo' to a todo list
post "/lists/:id/todos" do
  @list = find_list_by_id(params[:id])
  text = params[:todo].strip

  error = error_for_todo(@list, text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: params[:todo], completed: false } # Append todo object to todo array of list object
    session[:success] = "The todo '#{params[:todo]}' was added successfully."
    redirect "/lists/#{params[:id]}"
  end
end

post "/lists/:id/todos/:index/destroy" do
  @list = find_list_by_id(params[:id])
  index = params[:index].to_i
  deleted_item = @list[:todos].delete_at(index)[:name]

  session[:success] = "'#{deleted_item}' todo was removed successfully."
  redirect "/lists/#{params[:id]}"
end

# Toggles completion status of all todos
post "/lists/:id/complete_all" do
  @list = find_list_by_id(params[:id])
  @list[:all_completed] = !@list[:all_completed]
  
  @list[:todos].each do |todo|
    todo[:completed] = @list[:all_completed] ? true : false
  end

  session[:success] = "All todos have been marked as #{@list[:all_completed] ? 'completed' : 'incomplete' }."
  redirect "/lists/#{params[:id]}"
end

# Toggle completion status of todo
post "/lists/:id/todos/:index" do
  @list = find_list_by_id(params[:id])
  index = params[:index].to_i
  name = @list[:todos][index][:name]
  is_completed = params[:completed] == 'true'

  @list[:todos][index][:completed] = is_completed
  @list[:all_completed] = check_completion_of_all_todos(@list)
  session[:success] = "The todo '#{name}' has been marked as #{is_completed ? 'completed' : 'incomplete'}. #{ @list[:all_completed] ? "'#{@list[:name]}' is complete!" : '' }"
  redirect "/lists/#{params[:id]}"
end

# Return an error message if the name is invalid. Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name && list[:id] != params[:id] } # The second condition of the `any?` method block allows the user to 'Save' the edited list, even if the list's name is = to its previous name
    "The list's name must be unique."
  end
end

def check_completion_of_all_todos(list)
  list[:todos].all? { |todo| todo[:completed] == true }
end

def find_list_by_id(id)
  session[:lists].find do |list|
    list.key(id)
  end
end

def error_for_todo(list, text)
  if !(1..100).cover? text.size
    "Todo name must be between 1 and 100 characters."
  elsif list[:todos].any? { |todo| todo[:name] == text }
    "The todo's name must be unique."
  end
end

helpers do
  def todo_completion_counter(list)
    complete = 0
    list[:todos].each do |todo|
       if todo[:completed] == true
        complete += 1
       end
    end

    complete
  end

  def todos_count(list)
    list[:todos].size
  end
end