require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def list_name(id)
    # find_list_by_id(id)[:name]
  end

  def list_id(list_name)
    # all_lists.find {|list| list[:name] == list_name }[:id]
  end

  def list_status(id)
    # find_list_by_id(id)[:all_completed]
  end

  def todo_status(list_id, todo_id)
    # list = find_list_by_id(list_id)
    # find_todo_by_id(list, todo_id)[:completed]
  end

  def todo_name(list_id, todo_id)
    # list = find_list_by_id(list_id)
    # find_todo_by_id(list, todo_id)[:name]
  end

  def all_lists
    sql_lists = "SELECT * FROM lists"
    result_lists = query(sql_lists) # [{id:, name:, todos:}]

    result_lists.map do |list|
      list_id = list["id"].to_i
      todos = find_todos_for_list(list_id)
      { id: list_id, name: list["name"], todos: todos, all_completed: (list["all_completed"] == 't') }
    end
  end

  def create_new_list(list_name)
    # list = { name: list_name, id: SecureRandom.hex(2), todos: [], all_completed: false }
    # @session[:lists] << list
  end

  def delete_list(id)
    # list = find_list_by_id(id)
    # @session[:lists].delete(list)
  end

  def update_list_name(id, new_name)
    # list = find_list_by_id(id)
    # list[:name] = new_name
  end

  def create_new_todo(list_id, todo_name)
    # list = find_list_by_id(list_id)
    # todo_id = next_todo_id(list[:todos])
    # list[:todos] << { id: todo_id, name: todo_name, completed: false } # Append todo object to todo array of list object
  end

  def delete_todo(list_id, todo_id)
    # list = find_list_by_id(list_id)
    # todo = find_todo_by_id(list, todo_id)
    # list[:todos].delete(todo)[:name]
  end

  def toggle_todo_status(list_id, todo_id, is_completed)
    # list = find_list_by_id(list_id)
    # todo = find_todo_by_id(list, todo_id)

    # todo[:completed] = is_completed
    # list[:all_completed] = check_completion_of_all_todos(list)
  end

  def toggle_all_todos_status(id)
    # list = find_list_by_id(id)
    # list[:all_completed] = !list[:all_completed]
    
    # list[:todos].each do |todo|
    #   todo[:completed] = list[:all_completed] ? true : false
    # end
  end

  def is_list_complete?(id)
    # list = find_list_by_id(id)
    # list[:todos].all? { |todo| todo[:completed] == true }
  end

  def find_list_by_id(list_id)
    sql = "SELECT * FROM lists WHERE id = $1"
    sql_todos = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    todos = find_todos_for_list(list_id)

    tuple = result.first
    {id: tuple["id"], name: tuple["name"], todos: todos}
  end

  private

  def find_todos_for_list(list_id)
    sql_todos = "SELECT * FROM todos WHERE list_id = $1"
      result_todos = query(sql_todos, list_id)

      todos = result_todos.map do |todo|
        { id: todo["id"].to_i, 
          name: todo["name"], 
          completed: (todo["completed"] == 't') }
      end
  end

  def check_completion_of_all_todos(list)
    # list[:todos].all? { |todo| todo[:completed] == true }
  end

  def find_todo_by_id(list, todo_id)
    # todo = list[:todos].find { |todo| todo.key(todo_id) }
    # return todo if todo
  end
end