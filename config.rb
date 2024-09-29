class Config
  def self.telegram_bot_token
    ENV['TELEGRAM_BOT_TOKEN'] 
  end

  def self.allowed_chat_id
    ENV['ALLOWED_CHAT_ID'] 
  end

  def self.host
    ENV['DB_HOST']
  end

  def self.username
    ENV['DB_USERNAME']
  end

  def self.password
    ENV['DB_PASSWORD']
  end

  def self.database
    ENV['DB_DATABASE']
  end

  def self.ssl_certificate_path
    ENV['DB_SSL_CERTIFICATE_PATH']
  end
end