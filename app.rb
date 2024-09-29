require 'telegram/bot'
require_relative 'config'
require_relative 'multi_logger'
require_relative 'expense_tracker'
require_relative 'bot_commands'
require 'dotenv'

Dotenv.load

timestamp = Time.now.strftime('%Y_%m_%d_%H_%M_%S')
log_file = "logs/telegram_bot_logs_#{timestamp}.log"
Dir.mkdir('logs') unless Dir.exist?('logs')

file_logger = Logger.new(log_file)
stderr_logger = Logger.new(STDERR)

formatter = proc do |severity, datetime, progname, msg|
  "#{datetime}: #{severity} - #{msg}\n"
end

file_logger.formatter = formatter
stderr_logger.formatter = formatter

logger = MultiLogger.new(file_logger, stderr_logger)
token = Config.telegram_bot_token
allowed_chat_id = Config.allowed_chat_id

logger.info("Starting Telegram bot...")

begin
  if token.nil? || token.strip.empty?
    raise 'Telegram bot token is not set or is empty.'
  end

  if allowed_chat_id.nil? || allowed_chat_id.strip.empty?
    raise 'Allowed chat ID is not set, is empty, or is "unknown".'
  end

  db_config = {
    host: Config.host,
    username: Config.username,
    password: Config.password,
    database: Config.database,
    sslca: Config.ssl_certificate_path
  }

  expense_tracker = ExpenseTracker.new(db_config, logger)
  logger.info("Success!")
rescue StandardError => e
  logger.error("An error occurred: #{e.message}")
  logger.error(e.backtrace.join("\n"))
  raise e
end

begin
  Telegram::Bot::Client.run(token) do |bot|
    bot.listen do |message|
      begin
        if message.is_a?(Telegram::Bot::Types::Message) && message.chat.id == allowed_chat_id.to_i
          logger.info("Received message from chat ID #{message.chat.id}: #{message.text}")
          case message.text
          when '/help'
            BotCommands.help_message(bot, message, logger)
          when /^\/add\s+(.+)$/
            BotCommands.add_expense(bot, message, logger, expense_tracker)
          when /^\/remove\s+(\d+)$/
            BotCommands.remove_expense(bot, message, logger, expense_tracker)
          when /^\/last\s+(\d+)$/
            BotCommands.list_recent_expenses(bot, message, logger, expense_tracker)
          when /^\/top\s+(\d+)$/
            BotCommands.largest_expenses(bot, message, logger, expense_tracker)
          when /^\/budget$/
            BotCommands.check_budget(bot, message, logger, expense_tracker)
          when /^\/update_budget\s+(\d+(\.\d+)?)$/
            BotCommands.update_budget(bot, message, logger, expense_tracker)
          when /^\/dbudget$/
            BotCommands.check_daily_budget(bot, message, logger, expense_tracker)
          when /^\/wbudget$/
            BotCommands.check_weekly_budget(bot, message, logger, expense_tracker)
          when /^\/date\s+(\d{4}-\d{2}-\d{2})$/
            BotCommands.expenses_for_date(bot, message, logger, expense_tracker)
          when '/export'
            BotCommands.export_expenses(bot, message, logger, expense_tracker)
          else
            response = "Unknown command"
            bot.api.send_message(chat_id: message.chat.id, text: response)
            logger.info("Sent message: #{response}")
          end
        else
          logger.warn("Invalid message, chat id: #{message.chat.id}")
        end
      rescue Exception => e
        logger.error("An error occurred while handling message: #{e.message}")
        logger.error(e.backtrace.join("\n"))
      end
    end
  end
rescue Exception => e
  logger.error("An error occurred: #{e.message}")
  logger.error(e.backtrace.join("\n"))
  retry
end
