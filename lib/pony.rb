require 'mail'
require 'base64'

# = The express way to send email in Ruby
#
# == Overview
#
# Ruby no longer has to be jealous of PHP's mail() function, which can send an email in a single command.
#
#   Pony.mail(:to => 'you@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Hello there.')
#   Pony.mail(:to => 'you@example.com', :html_body => '<h1>Hello there!</h1>', :body => "In case you can't read html, Hello there.")
#   Pony.mail(:to => 'you@example.com', :cc => 'him@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Howsit!')
#
# Any option key may be omitted except for :to. For a complete list of options, see List Of Options section below.
#
#
# == Transport
#
# Pony uses /usr/sbin/sendmail to send mail if it is available, otherwise it uses SMTP to localhost.
#
# This can be over-ridden if you specify a via option:
#
#   Pony.mail(:to => 'you@example.com', :via => :smtp) # sends via SMTP
#
#   Pony.mail(:to => 'you@example.com', :via => :sendmail) # sends via sendmail
#
# You can also specify options for SMTP:
#
#   Pony.mail(:to => 'you@example.com', :via => :smtp, :via_options => {
#     :address        => 'smtp.yourserver.com',
#     :port           => '25',
#     :user_name      => 'user',
#     :password       => 'password',
#     :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
#     :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
#   }
#
# Gmail example (with TLS/SSL)
#
#   Pony.mail(:to => 'you@example.com', :via => :smtp, :via_options => {
#     :address              => 'smtp.gmail.com',
#     :port                 => '587',
#     :enable_starttls_auto => true,
#     :user_name            => 'user',
#     :password             => 'password',
#     :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
#     :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
#   })
#
# And options for Sendmail:
#
#   Pony.mail(:to => 'you@example.com', :via => :smtp, :via_options => {
#     :location  => '/path/to/sendmail' # this defaults to 'which sendmail' or '/usr/sbin/sendmail' if 'which' fails
#     :arguments => '-t' # -t and -i are the defaults
#   }
#
# == Attachments
#
# You can attach a file or two with the :attachments option:
#
#   Pony.mail(..., :attachments => {"foo.zip" => File.read("path/to/foo.zip"), "hello.txt" => "hello!"})
#
# Note: An attachment's mime-type is set based on the filename (as dictated by the ruby gem mime-types).  So 'foo.pdf' has a mime-type of 'application/pdf'
#
# == Custom Headers
#
# Pony allows you to specify custom mail headers
#   Pony.mail(
#     :to => 'me@example.com',
#     :headers => { "List-ID" => "...", "X-My-Custom-Header" => "what a cool custom header" }
#   )
#
# == List Of Options
#
# Options passed pretty much directly to Mail
#  to
#  cc
#  bcc
#  from
#  body # the plain text body
#  html_body # for sending html-formatted email
#  subject
#  charset # In case you need to send in utf-8 or similar
#  text_part_charset # for multipart messages, set the charset of the text part
#  attachments # see Attachments section above
#  headers # see Custom headers section above
#  message_id
#  sender  # Sets "envelope from" (and the Sender header)
#  reply_to
#
# Other options
#  via # :smtp or :sendmail, see Transport section above
#  via_options # specify transport options, see Transport section above
#
# == Set default options
#
# Default options can be set so that they don't have to be repeated. The default options you set will be overriden by any options you pass in to Pony.mail()
#
#   Pony.options = { :from => 'noreply@example.com', :via => :smtp, :via_options => { :host => 'smtp.yourserver.com' } }
#   Pony.mail(:to => 'foo@bar') # Sends mail to foo@bar from noreply@example.com using smtp
#   Pony.mail(:from => 'pony@example.com', :to => 'foo@bar') # Sends mail to foo@bar from pony@example.com using smtp


module Pony

  @@options = {}

# Default options can be set so that they don't have to be repeated.
#
#   Pony.options = { :from => 'noreply@example.com', :via => :smtp, :via_options => { :host => 'smtp.yourserver.com' } }
#   Pony.mail(:to => 'foo@bar') # Sends mail to foo@bar from noreply@example.com using smtp
#   Pony.mail(:from => 'pony@example.com', :to => 'foo@bar') # Sends mail to foo@bar from pony@example.com using smtp
  def self.options=(value)
    @@options = value
  end

  def self.options()
    @@options
  end

# Send an email
#   Pony.mail(:to => 'you@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Hello there.')
#   Pony.mail(:to => 'you@example.com', :html_body => '<h1>Hello there!</h1>', :body => "In case you can't read html, Hello there.")
#   Pony.mail(:to => 'you@example.com', :cc => 'him@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Howsit!')
  def self.mail(options)
    options = @@options.merge options
    raise(ArgumentError, ":to is required") unless options[:to]

    options[:via] = default_delivery_method unless options.has_key?(:via)

    options = cross_reference_depricated_fields(options)

    if options.has_key?(:via) && options[:via] == :sendmail
      options[:via_options] ||= {}
      options[:via_options][:location] ||= sendmail_binary
    end

    deliver build_mail(options)
  end

  private

  def self.cross_reference_depricated_fields(options)
    if options.has_key?(:smtp)
      warn depricated_message(:smtp, :via_options)
      options[:via_options] = options.delete(:smtp)
    end

    # cross-reference pony options to be compatible with keys mail expects
    { :host => :address, :user => :user_name, :auth => :authentication, :tls => :enable_starttls_auto }.each do |key, val|
      if options[:via_options] && options[:via_options].has_key?(key)
        warn depricated_message(key, val)
        options[:via_options][val] = options[:via_options].delete(key)
      end
    end

    if options[:content_type] && options[:content_type] =~ /html/ && !options[:html_body]
      warn depricated_message(:content_type, :html_body)
      options[:html_body] = options[:body]
    end

    return options
  end

  def self.deliver(mail)
    mail.deliver!
  end

  def self.default_delivery_method
    File.executable?(sendmail_binary) ? :sendmail : :smtp
  end

  def self.build_mail(options)
    mail = Mail.new do
      to options[:to]
      from options[:from] || 'pony@unknown'
      cc options[:cc]
      reply_to options[:reply_to]
      bcc options[:bcc]
      subject options[:subject]
      date options[:date] || Time.now
      message_id options[:message_id]
      sender options[:sender] if options[:sender]

      if options[:html_body]
        html_part do
          content_type 'text/html; charset=UTF-8'
          body options[:html_body]
        end
      end

      # If we're using attachments, the body needs to be a separate part. If not,
                        # we can just set the body directly.
      if options[:body] && (options[:html_body] || options[:attachments])
        text_part do
          body options[:body]
        end
      elsif options[:body]
        body options[:body]
      end

      delivery_method options[:via], (options.has_key?(:via_options) ? options[:via_options] : {})
                end

    (options[:attachments] || []).each do |name, body|
      # mime-types wants to send these as "quoted-printable"
      if name =~ /\.xlsx$/
        mail.attachments[name] = {
          :content => Base64.encode64(body),
          :transfer_encoding => :base64
        }
      else
        mail.attachments[name] = body
      end
    end

    (options[:headers] ||= {}).each do |key, value|
      mail[key] = value
    end

    mail.charset = options[:charset] if options[:charset] # charset must be set after setting content_type

    if mail.multipart? && options[:text_part_charset]
      mail.text_part.charset = options[:text_part_charset]
    end

    mail
  end

  def self.sendmail_binary
    sendmail = `which sendmail`.chomp
    sendmail.empty? ? '/usr/sbin/sendmail' : sendmail
  end

  def self.depricated_message(method, alternative)
    warning_message = "warning: '#{method}' is deprecated"
    warning_message += "; use '#{alternative}' instead." if alternative
    return warning_message
  end
end
