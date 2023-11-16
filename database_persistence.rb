require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
        PG.connect(ENV['DATABASE_URL'])
      else
        PG.connect(dbname: "todos")
      end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def list_name(list_id)
    sql_lists = "SELECT name FROM lists WHERE id = $1"
    query(sql_lists, list_id).first["name"]
  end

  def list_id(list_name)
    sql_lists = "SELECT id FROM lists WHERE name = $1"
    query(sql_lists, list_name).first["id"]
  end

  def list_status(list_id)
    sql_lists = "SELECT all_completed FROM lists WHERE id = $1"
    query(sql_lists, list_id).first["all_completed"] == 't'
  end

  def todo_status(list_id, todo_id)
    sql_lists = "SELECT completed FROM todos WHERE id = $1 AND list_id = $2"
    query(sql_lists, todo_id, list_id).first["completed"]
  end

  def todo_name(list_id, todo_id)
    sql_lists = "SELECT name FROM todos WHERE id = $1 AND list_id = $2"
    query(sql_lists, todo_id, list_id).first["name"]
  end

  def all_lists
    sql_lists = <<-SQL
      SELECT lists.*,
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, false)) AS todos_completed_count
      FROM lists
      LEFT JOIN todos ON todos.list_id = lists.id
      GROUP BY lists.id
      ORDER BY lists.name;
    SQL
    result_lists = query(sql_lists) # [{id:, name:, todos:}]

    result_lists.map do |list|
      { id: list["id"].to_i, 
        name: list["name"], 
        todos_count: list["todos_count"], 
        todos_completed_count: list["todos_completed_count"], 
        all_completed: (list["all_completed"] == 't') }
    end
  end

  def create_new_list(list_name)
    sql_lists = "INSERT INTO lists (name) VALUES ($1)"
    query(sql_lists, list_name)
  end

  def delete_list(list_id)
    sql_lists = "DELETE FROM lists WHERE id = $1"
    query(sql_lists, list_id)
  end

  def update_list_name(list_id, new_name)
    sql_lists = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql_lists, new_name, list_id)
  end

  def create_new_todo(list_id, todo_name)
    sql_todos = "INSERT INTO todos (name, list_id) VALUES ($1, $2)"
    query(sql_todos, todo_name, list_id)
  end

  def delete_todo(list_id, todo_id)
    sql_todos = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql_todos, todo_id, list_id)
  end

  def toggle_todo_status(list_id, todo_id, is_completed)
    sql_todos = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(sql_todos, is_completed, todo_id, list_id)

    auto_update_list_all_completed(list_id)
  end

  def toggle_all_todos_status(list_id)
    list_completion_status = is_list_complete?(list_id)
    sql_todos = "UPDATE todos SET completed = $1 WHERE list_id = $2"
    query(sql_todos, !list_completion_status, list_id)
    auto_update_list_all_completed(list_id)
  end

  def is_list_complete?(list_id)
    sql_lists = <<-SQL
      SELECT CASE 
        WHEN EXISTS(
          SELECT * FROM todos WHERE list_id = $1 AND completed = 'f'
        ) THEN 'f'
        ELSE 't'
      END AS all_completed
    SQL
    query(sql_lists, list_id).first["all_completed"] == 't'
  end

  def find_list_by_id(list_id)
    sql = "SELECT * FROM lists WHERE id = $1"
    sql_todos = "SELECT * FROM todos WHERE list_id = $1"
    result = query(sql, list_id)
    todos = find_todos_for_list(list_id)

    tuple = result.first
    {id: tuple["id"], name: tuple["name"], todos: todos, all_completed: (tuple["all_completed"] == 't')}
  end

  private

  def auto_update_list_all_completed(list_id)
    list_completion_status = is_list_complete?(list_id)
    sql_lists = "UPDATE lists SET all_completed = $1 WHERE id = $2"
    query(sql_lists, list_completion_status, list_id)
  end

  def find_todos_for_list(list_id)
    sql_todos = "SELECT * FROM todos WHERE list_id = $1"
      result_todos = query(sql_todos, list_id)

      todos = result_todos.map do |todo|
        { id: todo["id"].to_i, 
          name: todo["name"], 
          completed: (todo["completed"] == 't') }
      end
  end
end