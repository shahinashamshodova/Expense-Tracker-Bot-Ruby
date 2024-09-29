require_relative 'expense_tracker'

module BotCommands
  def self.help_message(bot, message, logger)
    response = [
      "Here are the available commands:",
      "",
      "/add <amount> <description> [date] - Adds a new expense.",
      "Example: /add 50 Dinner 2024-09-15",
      "Example: /add 50 Dinner",
      "If no date is given, today's date is used.",
      "",
      "/remove <id> - Removes an expense by ID.",
      "Example: /remove 3",
      "",
      "/last <number> - Lists the most recent expenses.",
      "Example: /last 5",
      "",
      "/budget - Checks if you are within your monthly budget.",
      "Example: /budget",
      "",
      "/update_budget <amount> - Updates the budget.",
      "Example: /update_budget 1500",
      "",
      "/dbudget - Checks if you are within your daily budget.",
      "Example: /dbudget",
      "",
      "/wbudget - Checks if you are within your weekly budget.",
      "Example: /wbudget",
      "",
      "/date <date> - Lists transactions for date.",
      "Example: /date 2024-09-18",
      "",
      "/top <number> - List largest expenses.",
      "Example: /top 10",
      "/export - Export as csv.",
      "Example: /export"
    ].join("\n")
    
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent help message")
  end

  def self.add_expense(bot, message, logger, expense_tracker)
    tokens = message.text.split[1..-1] # Get all tokens after /add
    expense_amount = tokens[0]
    
    # Check for optional date at the end
    if tokens.size > 2 && tokens[-1] =~ /\d{4}-\d{2}-\d{2}/
      expense_date = tokens.pop
    else
      expense_date = Date.today.to_s
    end
    
    expense_description = tokens[1..-1].join(' ')
    expense_tracker.add_expense(expense_amount.to_f, expense_description, expense_date)
    
    response = "Expense added: Amount=#{expense_amount}, Description=#{expense_description}, Date=#{expense_date}"
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent message: #{response}")
  end

  def self.remove_expense(bot, message, logger, expense_tracker)
    expense_id = message.text.split[1]
    expense_tracker.remove_expense(expense_id.to_i)
    response = "Expense with ID #{expense_id} removed."
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent message: #{response}")
  end

  def self.list_recent_expenses(bot, message, logger, expense_tracker)
    limit = message.text.split[1].to_i
    expenses = expense_tracker.list_recent_expenses(limit)
    response = expenses.join("\n")
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent message with recent expenses")
  end

  def self.largest_expenses(bot, message, logger, expense_tracker)
    limit = message.text.split[1].to_i
    expenses = expense_tracker.largest_transactions(limit)
    response = expenses.join("\n")
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent message with top #{limit} largest expenses")
  end

  def self.check_budget(bot, message, logger, expense_tracker)
    budget_message = expense_tracker.check_budget
    bot.api.send_message(chat_id: message.chat.id, text: budget_message)
    logger.info("Sent budget status")
  end

  def self.update_budget(bot, message, logger, expense_tracker)
    new_budget = message.text.split[1].to_f
    expense_tracker.update_budget(new_budget)
    response = "Budget updated to #{new_budget}."
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Updated budget to #{new_budget}")
  end

  def self.check_daily_budget(bot, message, logger, expense_tracker)
    daily_budget_message = expense_tracker.check_daily_budget
    bot.api.send_message(chat_id: message.chat.id, text: daily_budget_message)
    logger.info("Sent daily budget status")
  end

  def self.check_weekly_budget(bot, message, logger, expense_tracker)
    weekly_budget_message = expense_tracker.check_weekly_budget
    bot.api.send_message(chat_id: message.chat.id, text: weekly_budget_message)
    logger.info("Sent weekly budget status")
  end

  def self.expenses_for_date(bot, message, logger, expense_tracker)
    date = message.text.split[1]
    expenses = expense_tracker.expenses_for_date(date)
    response = expenses.empty? ? "No transactions found for #{date}." : expenses.join("\n")
    bot.api.send_message(chat_id: message.chat.id, text: response)
    logger.info("Sent message with expenses for date #{date}")
  end

  def self.export_expenses(bot, message, logger, expense_tracker)
    file_path = 'expenses.csv'
    expense_tracker.export_expenses_as_csv(file_path)
    bot.api.send_document(chat_id: message.chat.id, document: Faraday::UploadIO.new(file_path, 'text/csv'))
  end
end
