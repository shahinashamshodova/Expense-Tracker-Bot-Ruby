require 'logger'

class MultiLogger
  def initialize(*loggers)
    @loggers = loggers
  end

  def method_missing(method_name, *args, &block)
    @loggers.each do |logger|
      logger.public_send(method_name, *args, &block)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @loggers.any? { |logger| logger.respond_to?(method_name) } || super
  end
end