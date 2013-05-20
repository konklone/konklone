# utilities for sending email

class Email
  
  def self.message(message)
    send_email message, message, config[:admin][:email]
  end

  def self.exception(exception, attributes = {})
    name = exception.class.name
    message = exception.message
    subject = "#{name}: #{message}"

    body = "#{exception.class.to_s}: #{exception.message}\n\n" 
    
    if exception.backtrace.respond_to?(:each)
      exception.backtrace.each {|line| body += "#{line}\n"}
    end

    body += "\n\n#{JSON.pretty_generate attributes}" if attributes.any?

    send_email subject, body, config[:admin][:email]
  end

  def self.send_email(subject, body, to)
    if config['email'][:from]
      Pony.mail config['email'].merge(
        subject: subject, 
        body: body, 
        to: to
      )
    else
      puts "[FAKE] Sending to #{to}:\n\n#{subject}\n\n#{body}"
    end
  rescue Errno::ECONNREFUSED
    puts "Couldn't email report, connection refused! Check system settings."
  end
end