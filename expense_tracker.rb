require 'mysql2'
require 'date'
require 'csv'

class ExpenseTracker
  DEFAULT_BUDGET = 1300.0

  def initialize(db_config, logger)
    @db_config = db_config
    @logger = logger
    connect_to_db
    setup_schema
  end

  def connect_to_db
    begin
      @client = Mysql2::Client.new(
        host: @db_config[:host],
        username: @db_config[:username],
        password: @db_config[:password],
        database: @db_config[:database],
        sslca: @db_config[:sslca],
        sslverify: false,
        reconnect: true,
        read_timeout: 5,
        write_timeout: 5,
        connect_timeout: 5
      )
      @logger.info("Successfully reconnected!")
    rescue Exception => e
      @logger.error("Failed to reconnect.")
      raise e
    end
  end

  def ensure_connected
    begin
      @logger.info("Checking connection...")
      result = @client.ping
      if not result
        raise 'Ping failed, it returned FALSE.'
      end
      @logger.info("Ping successful!")
    rescue Exception => e
      @logger.error("Connection not working, attempting to reconnect...")
      connect_to_db
    end
  end

  def setup_schema
    ensure_connected
    @client.query <<-SQL
      CREATE TABLE IF NOT EXISTS expenses (
        expense_id INT AUTO_INCREMENT PRIMARY KEY,
        expense_amount DECIMAL(10, 2),
        expense_description TEXT,
        expense_date DATE
      );
    SQL

    @client.query <<-SQL
      CREATE TABLE IF NOT EXISTS budget (
        id INT PRIMARY KEY,
        amount DECIMAL(10, 2)
      );
    SQL

    result = @client.query("SELECT * FROM budget").first
    unless result
      @client.query("INSERT INTO budget (id, amount) VALUES (1, #{DEFAULT_BUDGET})")
    end
  end

  def format_amount(amount)
    format('%.2f', amount)
  end

  def add_expense(expense_amount, expense_description, expense_date)
    ensure_connected
    query = <<-SQL
      INSERT INTO expenses (expense_amount, expense_description, expense_date)
      VALUES (?, ?, ?)
    SQL
    statement = @client.prepare(query)
    statement.execute(expense_amount, expense_description, expense_date)
  end

  def remove_expense(expense_id)
    ensure_connected
    query = "DELETE FROM expenses WHERE expense_id = ?"
    statement = @client.prepare(query)
    statement.execute(expense_id)
  end

  def list_recent_expenses(limit)
    ensure_connected
    limit = limit.to_i

    query = <<-SQL
      SELECT * FROM expenses
      ORDER BY expense_date DESC
      LIMIT ?
    SQL

    statement = @client.prepare(query)
    results = statement.execute(limit)

    results.map do |row|
      "ID: #{row['expense_id']}, Amount: #{format_amount(row['expense_amount'])}, Description: #{row['expense_description']}, Date: #{row['expense_date']}"
    end
  end

  def check_budget
    ensure_connected
    current_date = Date.today
    past_30_days = current_date - 30
    past_30_days_str = past_30_days.strftime('%Y-%m-%d')

    query = <<-SQL
      SELECT SUM(expense_amount) AS total_expense
      FROM expenses
      WHERE expense_date >= ?
    SQL

    statement = @client.prepare(query)
    total_expense_row = statement.execute(past_30_days_str).first
    total_expense = total_expense_row['total_expense'].to_f

    budget_amount = get_budget
    difference = total_expense - budget_amount

    green_emoji = "✅"
    red_emoji = "❌"

    if difference > 0
      response = "🚨#{red_emoji} Overspent by #{difference.round(2)}\nTotal spent: #{total_expense.round(2)}\nBudget: #{budget_amount}\n(from #{past_30_days_str} to #{current_date.strftime('%Y-%m-%d')})."
    else
      response = "#{green_emoji} Underspent by #{-difference.round(2)}\nTotal spent: #{total_expense.round(2)}\nBudget: #{budget_amount}\n(from #{past_30_days_str} to #{current_date.strftime('%Y-%m-%d')})."
    end

    response
  end

  def get_budget
    ensure_connected
    query = "SELECT amount FROM budget WHERE id = 1"
    result = @client.query(query).first
    result ? result['amount'].to_f : DEFAULT_BUDGET
  end

  def update_budget(new_amount)
    ensure_connected
    query = "UPDATE budget SET amount = ? WHERE id = 1"
    statement = @client.prepare(query)
    statement.execute(new_amount)
  end

  def check_daily_budget
    ensure_connected
    current_date = Date.today
    query = <<-SQL
      SELECT SUM(expense_amount) AS total_expense
      FROM expenses
      WHERE expense_date = ?
    SQL

    statement = @client.prepare(query)
    total_expense_row = statement.execute(current_date.to_s).first
    total_expense = total_expense_row['total_expense'].to_f

    budget_amount = get_budget
    daily_budget = budget_amount / 30
    difference = total_expense - daily_budget

    green_emoji = "✅"
    red_emoji = "❌"

    if difference > 0
      response = "🚨#{red_emoji} Overspent today by #{difference.round(2)}\nTotal spent today: #{total_expense.round(2)}\nBudget for today: #{daily_budget.round(2)}"
    else
      response = "#{green_emoji} Underspent today by #{-difference.round(2)}\nTotal spent today: #{total_expense.round(2)}\nBudget for today: #{daily_budget.round(2)}"
    end

    response
  end

  def largest_transactions(limit)
    ensure_connected
    query = <<-SQL
      SELECT * FROM expenses
      ORDER BY expense_amount DESC
      LIMIT ?
    SQL

    statement = @client.prepare(query)
    results = statement.execute(limit)

    results.map do |row|
      "ID: #{row['expense_id']}, Amount: #{format_amount(row['expense_amount'])}, Description: #{row['expense_description']}, Date: #{row['expense_date']}"
    end
  end

  def expenses_for_date(date)
    ensure_connected
    query = <<-SQL
      SELECT * FROM expenses
      WHERE expense_date = ?
      ORDER BY expense_date DESC
    SQL

    statement = @client.prepare(query)
    results = statement.execute(date)

    results.map do |row|
      "ID: #{row['expense_id']}, Amount: #{format_amount(row['expense_amount'])}, Description: #{row['expense_description']}, Date: #{row['expense_date']}"
    end
  end

  def check_weekly_budget
    ensure_connected
    current_date = Date.today
    start_of_week = current_date - (current_date.wday - 1) % 7
    start_of_week = DateTime.new(start_of_week.year, start_of_week.month, start_of_week.day, 0, 0, 0)

    query = <<-SQL
      SELECT SUM(expense_amount) AS total_expense
      FROM expenses
      WHERE expense_date >= ?
        AND expense_date <= ?
    SQL

    statement = @client.prepare(query)
    total_expense_row = statement.execute(start_of_week.to_s, current_date.to_s).first
    total_expense = total_expense_row['total_expense'].to_f

    budget_amount = get_budget
    weekly_budget = 7 * budget_amount / 30
    difference = total_expense - weekly_budget

    green_emoji = "✅"
    red_emoji = "❌"

    if difference > 0
      response = "🚨#{red_emoji} Overspent this week by #{difference.round(2)}\nTotal spent this week: #{total_expense.round(2)}\nWeekly budget: #{weekly_budget.round(2)}"
    else
      response = "#{green_emoji} Underspent this week by #{-difference.round(2)}\nTotal spent this week: #{total_expense.round(2)}\nWeekly budget: #{weekly_budget.round(2)}"
    end

    response
  end

  def export_expenses_as_csv(file_path)
    ensure_connected

    query = "SELECT * FROM expenses"
    results = @client.query(query)

    CSV.open(file_path, "w") do |csv|
      csv << ["Expense ID", "Amount", "Description", "Date"]
      results.each do |row|
        csv << [row['expense_id'], format_amount(row['expense_amount']), row['expense_description'], row['expense_date']]
      end
    end
  end
end
