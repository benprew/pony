require 'mail'
require 'base64'
require 'socket'

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
#   Pony.mail(:to => 'you@example.com', :via => :sendmail, :via_options => {
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
  @@override_options = {}
  @@subject_prefix = false
  @@append_inputs = false

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

  def self.override_options=(value)
    @@override_options = value
  end

  def self.override_options
    @@override_options
  end

  def self.subject_prefix(value)
    @@subject_prefix = value
  end

  def self.append_inputs
    @@append_inputs = true
  end

# Send an email
#   Pony.mail(:to => 'you@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Hello there.')
#   Pony.mail(:to => 'you@example.com', :html_body => '<h1>Hello there!</h1>', :body => "In case you can't read html, Hello there.")
#   Pony.mail(:to => 'you@example.com', :cc => 'him@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Howsit!')
  def self.mail(options)
    if @@append_inputs
      options[:body] = "#{options[:body]}/n #{options.to_s}"
    end

    options = @@options.merge options
    options = options.merge @@override_options

    if @@subject_prefix
      options[:subject] = "#{@@subject_prefix}#{options[:subject]}"
    end

    fail ArgumentError, ':to is required' unless options[:to]

    options[:via] = default_delivery_method unless options.key?(:via)

    if options.key?(:via) && options[:via] == :sendmail
      options[:via_options] ||= {}
      options[:via_options][:location] ||= sendmail_binary
    end

    deliver build_mail(options)
  end

  def self.permissable_options
    standard_options + non_standard_options
  end

  class << self
    private

    def deliver(mail)
      mail.deliver!
    end

    def default_delivery_method
      File.executable?(sendmail_binary) ? :sendmail : :smtp
    end

    def standard_options
      [
        :to,
        :cc,
        :bcc,
        :from,
        :subject,
        :content_type,
        :message_id,
        :sender,
        :reply_to,
        :smtp_envelope_to
      ]
    end

    def non_standard_options
      [
        :attachments,
        :body,
        :charset,
        :enable_starttls_auto,
        :headers,
        :html_body,
        :text_part_charset,
        :via,
        :via_options,
        :body_part_header,
        :html_body_part_header
      ]
    end

    def build_mail(options)
      nso = non_standard_options
      mail = Mail.new do |m|
        options[:date] ||= Time.now
        options[:from] ||= 'pony@unknown'
        options[:via_options] ||= {}

        options.each do |k, v|
          next if nso.include?(k)
          m.send(k, v)
        end

        m.delivery_method options[:via], options[:via_options]
      end

      # Automatic handling of multipart messages in the underlying
      # mail library works pretty well for the most part, but in
      # the case where we have attachments AND text AND html bodies
      # we need to explicitly define a second multipart/alternative
      # boundary to encapsulate the body-parts within the
      # multipart/mixed boundary that will be created automatically.
      if options[:attachments] && options[:html_body] && options[:body]
        mail.part(:content_type => 'multipart/alternative') do |p|
          p.html_part = build_html_part(options)
          p.text_part = build_text_part(options)
        end

      # Otherwise if there is more than one part we still need to
      # ensure that they are all declared to be separate.
      elsif options[:html_body] || options[:attachments]
        mail.html_part = build_html_part(options) if options[:html_body]
        mail.text_part = build_text_part(options) if options[:body]

      # If all we have is a text body, we don't need to worry about parts.
      elsif options[:body]
        mail.body options[:body]
      end

      (options[:headers] ||= {}).each do |key, value|
        mail[key] = value
      end

      add_attachments(mail, options[:attachments]) if options[:attachments]

      mail.charset = options[:charset] if options[:charset] # charset must be set after setting content_type

      if mail.multipart? && options[:text_part_charset]
        mail.text_part.charset = options[:text_part_charset]
      end
      set_content_type(mail, options[:content_type])
      mail
    end

    def build_html_part(options)
      Mail::Part.new(:content_type => 'text/html;charset=UTF-8') do
        content_transfer_encoding 'quoted-printable'
        body Mail::Encodings::QuotedPrintable.encode(options[:html_body])
        if options[:html_body_part_header] && options[:html_body_part_header].is_a?(Hash)
          options[:html_body_part_header].each do |k,v|
            header[k] = v
          end
        end
      end
    end

    def build_text_part(options)
      Mail::Part.new(:content_type => 'text/plain') do
        content_type options[:charset] if options[:charset]
        body options[:body]
        if options[:body_part_header] && options[:body_part_header].is_a?(Hash)
          options[:body_part_header].each do |k,v|
            header[k] = v
          end
        end
      end
    end

    def set_content_type(mail, user_content_type)
      params = mail.content_type_parameters || {}
      content_type =
        case
        when user_content_type
          user_content_type
        when mail.has_attachments?
          if mail.attachments.detect { |a| a.inline? }
            ["multipart", "related", params]
          else
            ["multipart", "mixed", params]
          end
        when mail.multipart?
          ["multipart", "alternative", params]
        else
          false
        end
      mail.content_type = content_type if content_type
    end

    def add_attachments(mail, attachments)
      attachments.each do |name, body|
        name = name.gsub /\s+/, ' '

        # mime-types wants to send these as "quoted-printable"
        if name =~ /\.xlsx$/
          mail.attachments[name] = {
            :content => Base64.encode64(body),
            :transfer_encoding => :base64
          }
        else
          mail.attachments[name] = body
        end
        mail.attachments[name].add_content_id("<#{name}@#{Socket.gethostname}>")
      end
    end

    def sendmail_binary
      sendmail = `which sendmail`.chomp
      sendmail.empty? ? '/usr/sbin/sendmail' : sendmail
    end
  end
end
