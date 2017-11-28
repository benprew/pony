# Pony, the express way to send email in Ruby #

## Overview ##

Ruby no longer has to be jealous of PHP's mail() function, which can send an email in a single command.

    Pony.mail(:to => 'you@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Hello there.')
    Pony.mail(:to => 'you@example.com', :html_body => '<h1>Hello there!</h1>', :body => "In case you can't read html, Hello there.")
    Pony.mail(:to => 'you@example.com', :cc => 'him@example.com', :from => 'me@example.com', :subject => 'hi', :body => 'Howsit!')

Any option key may be omitted except for ```:to```.  See List Of Options section for the complete list.

## Transport ##

Pony uses ```/usr/sbin/sendmail``` to send mail if it is available, otherwise it uses SMTP to localhost.

This can be overridden if you specify a via option:

    Pony.mail(:to => 'you@example.com', :via => :smtp) # sends via SMTP
    Pony.mail(:to => 'you@example.com', :via => :sendmail) # sends via sendmail

You can also specify options for SMTP:

    Pony.mail({
      :to => 'you@example.com',
      :via => :smtp,
      :via_options => {
        :address        => 'smtp.yourserver.com',
        :port           => '25',
        :user_name      => 'user',
        :password       => 'password',
        :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
        :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
      }
    })

Gmail example (with TLS/SSL)

    Pony.mail({
      :to => 'you@example.com',
      :via => :smtp,
      :via_options => {
        :address              => 'smtp.gmail.com',
        :port                 => '587',
        :enable_starttls_auto => true,
        :user_name            => 'user',
        :password             => 'password_see_note',
        :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
        :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
      }
    })

Note: If you use 2 step verification, you will have to generate an application specific password and NOT use your normal password - see https://support.google.com/accounts/answer/185833?hl=en

And options for Sendmail:

    Pony.mail({
      :to => 'you@example.com',
      :via => :sendmail,
      :via_options => {
        :location  => '/path/to/sendmail', # defaults to 'which sendmail' or '/usr/sbin/sendmail' if 'which' fails
        :arguments => '-t' # -t and -i are the defaults
      }
    })

If you're using smtp, set ```:arguments => ''```.

## Attachments ##

You can attach a file or two with the :attachments option:

    Pony.mail(..., :attachments => {"foo.zip" => File.read("path/to/foo.zip"), "hello.txt" => "hello!"})

Note: An attachment's mime-type is set based on the filename (as dictated by the ruby gem mime-types).  So 'foo.pdf' has a mime-type of 'application/pdf'

## Custom Headers ##

Pony allows you to specify custom mail headers

    Pony.mail(
      :to => 'me@example.com',
      :headers => { "List-ID" => "...", "X-My-Custom-Header" => "what a cool custom header" }
    )

Add additional options for headers in each part of letter (text, html)

    Pony.mail(
      :body => 'test',
      :html_body => 'What do you know, Joe?',
      :attachments => {"foo.txt" => "content of foo.txt"},
      :body_part_header => { content_disposition: "inline" }
    )

This will add option ```'Content-Disposition: inline'``` for text part header of letter.

Also you can add additional options for html part of latter, e.g.:

    :html_body_part_header => { content_disposition: "inline" }


## List Of Options ##

You can get a list of options from Pony directly:

    Pony.permissable_options

Options passed pretty much directly to Mail

    attachments # see Attachments section
    bcc
    body # the plain text body
    body_part_header # see Custom headers section
    cc
    charset # In case you need to send in utf-8 or similar
    content_type
    from
    headers # see Custom headers section
    html_body # for sending html-formatted email
    html_body_part_header # see Custom headers section
    message_id
    reply_to
    sender  # Sets "envelope from" (and the Sender header)
    smtp_envelope_to
    subject
    text_part_charset # for multipart messages, set the charset of the text part
    to

Other options
    via # :smtp or :sendmail, see Transport section
    via_options # specify transport options, see Transport section

### Default Options ###

Default options can be set so that they don't have to be repeated. The default options you set will be overriden by any options you pass in to Pony.mail()

    Pony.options = { :from => 'noreply@example.com', :via => :smtp, :via_options => { :host => 'smtp.yourserver.com' } }
    Pony.mail(:to => 'foo@bar') # Sends mail to foo@bar from noreply@example.com using smtp
    Pony.mail(:from => 'pony@example.com', :to => 'foo@bar') # Sends mail to foo@bar from pony@example.com using smtp


### Override Options ###

Override options can be set so that the override value is always be used, even if a different value is passed in to Pony.options() or Pony.mail(). This can be used to configure a development or staging environment.

    Pony.override_options = { :to => 'test@example.com' }
    Pony.mail(:to => 'foo@bar') # Sends mail to test@example.com instead of foo@bar

## Testing/Debugging Aids ##

[![Build Status](https://travis-ci.org/benprew/pony.svg?branch=master)](https://travis-ci.org/benprew/pony)

### Subject prefix ###

Prepends a string to the subject line.  This is used to identify email sent from a specific environment.

    Pony.subject_prefix('Prefix:')

### Append options to body ###

Append the options passd into Pony.mail to the body of the email.  Useful for debugging.

    Pony.append_inputs

### Using Pony with Testing or Spec'ing Libraries ###

As pony relies on mail to send the mails, you can also use its TestMailer in your tests.

    Pony.override_options = { :via => :test }
    Pony.mail(:to => 'foo@bar')
    Mail::TestMailer.deliveries.length
    => 1
    
For further examples see the [corresponding section of mail's readme](https://github.com/mikel/mail#using-mail-with-testing-or-specing-libraries)

## Help ##

If you need help using Pony, or it looks like you've found a bug,
email ponyrb@googlegroups.com.  The full forum is
https://groups.google.com/forum/#!forum/ponyrb

### Meta ###

* Released under the [MIT License](http://www.opensource.org/licenses/mit-license.php)
* [Homepage](http://github.com/benprew/pony)
* Mailing List: ponyrb@googlegroups.com

## Authors ##
*  Adam Wiggins  [@adamwiggins](https://github.com/adamwiggins)
*  Andrea Talbot  [@janehax](https://github.com/janehax)
*  Ben Prew  [@benprew](https://github.com/benprew)
*  Cameron Matheson  [@cmatheson](https://github.com/cmatheson)
*  Carl Hörberg  [@carlhoerberg](https://github.com/carlhoerberg)
*  Christian Haase  [@krissi](https://github.com/krissi)
*  Daniel Lopes  [@danielvlopes](https://github.com/danielvlopes)
*  Doug Hammond  [@dslh](https://github.com/dslh)
*  Hiroshi Saito  [@hiroshi](https://github.com/hiroshi)
*  Kalin Harvey
*  MIKAMI Yoshiyuki  [@yoshuki](https://github.com/yoshuki)
*  Mathieu Martin  [@webmat](https://github.com/webmat)
*  Michael Durrant  [@durrantm](https://github.com/durrantm)
*  Michał Kwiatkowski  [@mkwiatkowski](https://github.com/mkwiatkowski)
*  Nami-Doc
*  Neil Middleton  [@neilmiddleton](https://github.com/neilmiddleton)
*  Neil Mock  [@neilmock](https://github.com/neilmock)
*  Nickolas Means  [@nmeans](https://github.com/nmeans)
*  Othmane Benkirane  [@anaothmane](https://github.com/anaothmane)
*  Rich Meyers  [@richmeyers](https://github.com/richmeyers)
*  Roman Franko  [@roman-franko](https://github.com/roman-franko)
*  Ryan Malecky  [@rmalecky](https://github.com/rmalecky)
*  Seamus Abshere  [@seamusabshere](https://github.com/seamusabshere)
*  Stephen Celis  [@stephencelis](https://github.com/stephencelis)
*  Steve Root  [@steveroot](https://github.com/steveroot)
*  arunthampi  [@arunthampi](https://github.com/arunthampi)
*  rick  [@rick](https://github.com/rick)
*  rohit  [@rohit](https://github.com/rohit)

## Changelog ##

#### 1.12 ####
* fix bug: NoMethodError when using mail 2.7.0

#### 1.11 ####
* Improved handling of mails with both text and html bodies and attachments

#### 1.10 ####
* Add ```subject_prefix```, ```append_options``` and ```override_options```

#### 1.9 ####
* Allow options to be queried from the gem

#### 1.8 ####
* Add additional options for headers in each part of letter

#### 1.7 ####
* Better default content_type with attachments

#### 1.6 ####
* Unknown options are passed directly to mail to handle.  Remove deprecated syntax

#### 1.5.1 ####
* Loosen mail dependency to >= 2.0 instead of > 2.0

#### 1.5 ####
* Specify content-id of attachments as filename@hostname

#### 1.4.1 ####
* Update gemfile

#### 1.4 ####
* Updated docs

#### 1.3 ####
* Add new option ```:text_part_charset```, which allows you to specify the charset for the text portion

#### 1.2 ####
* Remove limitations on :via, and let mail handle it (this means you can say things like :via => test)
* Add reply-to option and a bundler file

#### 1.1 ####
* Add default options

#### 1.0 ####
* Convert to using Mail as the mail-generation backend, instead of TMail

#### 0.9.1 ####
* provide the ability to set custom mail headers with something like:
	Pony.mail(:headers => {"List-ID" => "..."})
* provide the ability to set the Message-Id from Pony.mail

#### 0.9 ####
* merge in kalin's fixes to use tmail.destinations instead of trying to parse tmail.to, tmail.cc and tmail.bcc.  New specs to test functionality

#### 0.8 ####
* Fix bug that was allowing nil :bcc and :cc options to be passed to smtp

#### 0.7 ####
* Pass :cc and :bcc options to sendmail appropriately

#### 0.6 ####
* Add :bcc capability
* Add :charset capability
* Add complete list of options to readme
* fix bug: readme examples

#### 0.5 ####
* default location of sendmail to /usr/sbin/sendmail if sendmail not in path
* fix bug: README not showing password option (listed as pass)

#### 0.4.1 ####
* Add :cc capability
* fix bug: resolve body not displaying when attachments sent

#### 0.4 ####
* Implemented file attachments option
* use TLS if :tls => true
