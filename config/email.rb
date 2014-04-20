# utilities for sending email

class Email

  def self.message(message)
    send_email message, message, Environment.config['admin']['email']
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

    send_email subject, body, Environment.config['admin']['email']
  end

  def self.flagged_comment(comment)
    subject = "Flagged comment by \"#{comment.author}\" on recent post"
    body = "#{Environment.config['site']['root']}/admin/comment/#{comment.id}"
    body += "\n\n"
    body += comment.author
    body += " - #{comment.author_url}" if comment.author_url.present?
    body += " (#{comment.author_email})"
    body += "\n\n"
    body += comment.body

    send_email subject, body, Environment.config['admin']['email']
  end


  ## workhorse

  def self.send_email(subject, body, to)
    if Environment.config['email']['from']

      # Pony demands symbol keys for everything, but using safe_yaml
      # commits us to string keys.
      options = {
        from: Environment.config['email']['from'],
        via: Environment.config['email']['via'].to_sym,
        via_options: {
          address: Environment.config['email']['via_options']['address'],
          port: Environment.config['email']['via_options']['port'],
          user_name: Environment.config['email']['via_options']['user_name'],
          password: Environment.config['email']['via_options']['password'],
          # authentication: Environment.config['email']['via_options']['authentication'],
          # domain: Environment.config['email']['via_options']['domain'],
          enable_starttls_auto: Environment.config['email']['via_options']['enable_starttls_auto']
        }
      }

      Pony.mail options.merge(
        subject: subject,
        body: body,
        to: to
      )
      puts "[REAL] Sent to #{to}:\n\n#{subject}\n\n#{body}"
    else
      puts "[FAKE] Sending to #{to}:\n\n#{subject}\n\n#{body}"
    end
  rescue Errno::ECONNREFUSED
    puts "Couldn't email report, connection refused! Check system settings."
  end
end