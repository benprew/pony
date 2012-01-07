# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/base'

describe Pony do

  before(:each) do
    Pony.stub!(:deliver)
  end

  it "sends mail" do
    Pony.should_receive(:deliver) do |mail|
      mail.to.should == [ 'joe@example.com' ]
      mail.from.should == [ 'sender@example.com' ]
      mail.subject.should == 'hi'
      mail.body.should == 'Hello, Joe.'
    end
    Pony.mail(:to => 'joe@example.com', :from => 'sender@example.com', :subject => 'hi', :body => 'Hello, Joe.')
  end

  it "requires :to param" do
    lambda { Pony.mail({}) }.should raise_error(ArgumentError)
  end

  it "doesn't require any other param" do
    lambda { Pony.mail(:to => 'joe@example.com') }.should_not raise_error
  end

  it "should handle depricated options gracefully" do
    Pony.should_receive(:build_mail).with(hash_including(:via_options => {:address => 'test'}))
    Pony.mail(:to => 'foo@bar', :smtp => { :host => 'test' }, :via => :smtp)
  end

  it "should handle depricated content-type gracefully" do
    Pony.should_receive(:build_mail).with(hash_including(:html_body => "this is <h1>HTML</h1>"))
    Pony.mail(:to => 'foo@bar', :content_type => 'text/html', :body => 'this is <h1>HTML</h1>')
  end
  ####################

  describe "builds a Mail object with field:" do
    it "to" do
      Pony.build_mail(:to => 'joe@example.com').to.should == [ 'joe@example.com' ]
    end
    
    it "to with multiple recipients" do
      Pony.build_mail(:to => 'joe@example.com, friedrich@example.com').to.should == [ 'joe@example.com', 'friedrich@example.com' ]
    end
    
    it "to with multiple recipients and names" do
      Pony.build_mail(:to => 'joe@example.com, "Friedrich Hayek" <friedrich@example.com>').to.should == [ 'joe@example.com', 'friedrich@example.com' ]
    end
    
    it "to with multiple recipients and names in an array" do
      Pony.build_mail(:to => ['joe@example.com', '"Friedrich Hayek" <friedrich@example.com>']).to.should == [ 'joe@example.com', 'friedrich@example.com' ]
    end

    it "cc" do
      Pony.build_mail(:cc => 'joe@example.com').cc.should == [ 'joe@example.com' ]
    end
    
    it "reply_to" do
      Pony.build_mail(:reply_to => 'joe@example.com').reply_to.should == [ 'joe@example.com' ]
    end    
    
    it "cc with multiple recipients" do
      Pony.build_mail(:cc => 'joe@example.com, friedrich@example.com').cc.should == [ 'joe@example.com', 'friedrich@example.com' ]
    end

    it "from" do
      Pony.build_mail(:from => 'joe@example.com').from.should == [ 'joe@example.com' ]
    end

    it "bcc" do
      Pony.build_mail(:bcc => 'joe@example.com').bcc.should == [ 'joe@example.com' ]
    end

    it "bcc with multiple recipients" do
      Pony.build_mail(:bcc => 'joe@example.com, friedrich@example.com').bcc.should == [ 'joe@example.com', 'friedrich@example.com' ]
    end

    it "charset" do
      mail = Pony.build_mail(:charset => 'UTF-8')
      mail.charset.should == 'UTF-8'
    end

    it "text_part_charset" do
      mail = Pony.build_mail(:attachments => {"foo.txt" => "content of foo.txt"}, :body => 'test', :text_part_charset => 'ISO-2022-JP')
      mail.text_part.charset.should == 'ISO-2022-JP'
    end

    it "default charset" do
      Pony.build_mail(:body => 'body').charset.should == 'UTF-8'
      Pony.build_mail(:body => 'body', :content_type => 'text/html').charset.should == 'UTF-8'
    end

    it "from (default)" do
      Pony.build_mail({}).from.should == [ 'pony@unknown' ]
    end

    it "subject" do
      Pony.build_mail(:subject => 'hello').subject.should == 'hello'
    end

    it "body" do
      Pony.build_mail(:body => 'What do you know, Joe?').body.should == 'What do you know, Joe?'
    end

    it "html_body" do
      Pony.build_mail(:html_body => 'What do you know, Joe?').parts.first.body.should == 'What do you know, Joe?'
      Pony.build_mail(:html_body => 'What do you know, Joe?').parts.first.content_type.should == 'text/html; charset=UTF-8'
    end

    it "date" do
      now = Time.now
      Pony.build_mail(:date => now).date.should == DateTime.parse(now.to_s)
    end

    it "content_type of html should set html_body" do
      Pony.should_receive(:build_mail).with(hash_including(:html_body => '<h1>test</h1>'))
      Pony.mail(:to => 'foo@bar', :content_type => 'text/html', :body => '<h1>test</h1>')
    end

    it "message_id" do
      Pony.build_mail(:message_id => '<abc@def.com>').message_id.should == 'abc@def.com'
    end

    it "custom headers" do
      Pony.build_mail(:headers => {"List-ID" => "<abc@def.com>"})['List-ID'].to_s.should == '<abc@def.com>'
    end

    it "sender" do
      Pony.build_mail(:sender => "abc@def.com")['Sender'].to_s.should == 'abc@def.com'
    end

    it "utf-8 encoded subject line" do
      mail = Pony.build_mail(:to => 'btp@foo', :subject => 'Café', :body => 'body body body')
      mail['subject'].encoded.should =~ /^Subject: =\?UTF-8/;
    end

    it "attachments" do
      mail = Pony.build_mail(:attachments => {"foo.txt" => "content of foo.txt"}, :body => 'test')
      mail.parts.length.should == 2
      mail.parts.first.to_s.should =~ /Content-Type: text\/plain/
    end

    it "suggests mime-type" do
      mail = Pony.build_mail(:attachments => {"foo.pdf" => "content of foo.pdf"})
      mail.parts.length.should == 1
      mail.parts.first.to_s.should =~ /Content-Type: application\/pdf/
      mail.parts.first.to_s.should =~ /filename=foo.pdf/
      mail.parts.first.content_transfer_encoding.to_s.should == 'base64'
    end

    it "encodes xlsx files as base64" do
      mail = Pony.build_mail(:attachments => {"foo.xlsx" => "content of foo.xlsx"})
      mail.parts.length.should == 1
      mail.parts.first.to_s.should =~ /Content-Type: application\/vnd.openxmlformats-officedocument.spreadsheetml.sheet/
      mail.parts.first.to_s.should =~ /filename=foo.xlsx/
      mail.parts.first.content_transfer_encoding.to_s.should == 'base64'
    end

    it "passes cc and bcc as the list of recipients" do
      mail = Pony.build_mail(:to => ['to'], :cc => ['cc'], :from => ['from'], :bcc => ['bcc'])
      mail.destinations.should ==  ['to', 'cc', 'bcc']
    end
  end

  describe "transport" do
    it "transports via smtp if no sendmail binary" do
      Pony.stub!(:sendmail_binary).and_return('/does/not/exist')
      Pony.should_receive(:build_mail).with(hash_including(:via => :smtp))
      Pony.mail(:to => 'foo@bar')
    end

    it "defaults to sendmail if no via is specified and sendmail exists" do
      File.stub!(:executable?).and_return(true)
      Pony.should_receive(:build_mail).with(hash_including(:via => :sendmail))
      Pony.mail(:to => 'foo@bar')
    end

    describe "SMTP transport" do

      it "defaults to localhost as the SMTP server" do
        mail = Pony.build_mail(:to => "foo@bar", :enable_starttls_auto => true, :via => :smtp)
        mail.delivery_method.settings[:address].should == 'localhost'
      end

      it "enable starttls when tls option is true" do
        mail = Pony.build_mail(:to => "foo@bar", :enable_starttls_auto => true, :via => :smtp)
        mail.delivery_method.settings[:enable_starttls_auto].should == true
      end
    end
  end

  describe ":via option should over-ride the default transport mechanism" do
    it "should send via sendmail if :via => sendmail" do
      mail = Pony.build_mail(:to => 'joe@example.com', :via => :sendmail)
      mail.delivery_method.kind_of?(Mail::Sendmail).should == true
    end

    it "should send via smtp if :via => smtp" do
      mail = Pony.build_mail(:to => 'joe@example.com', :via => :smtp)
      mail.delivery_method.kind_of?(Mail::SMTP).should == true
    end

  end

  describe "sendmail binary location" do
    it "should default to /usr/sbin/sendmail if not in path" do
      Pony.stub!(:'`').and_return('')
      Pony.sendmail_binary.should == '/usr/sbin/sendmail'
    end
  end

  describe "default options" do
    it "should use default options" do
      Pony.should_receive(:build_mail).with(hash_including(:from => 'noreply@pony'))
      Pony.options = { :from => 'noreply@pony' }
      Pony.mail(:to => 'foo@bar')
    end

    it "should merge default options with options" do
      Pony.should_receive(:build_mail).with(hash_including(:from => 'override@pony'))
      Pony.options = { :from => 'noreply@pony' }
      Pony.mail(:from => 'override@pony', :to => "foo@bar")
    end

    it "should return the default options" do
      input = { :from => 'noreply@pony' }
      Pony.options = input
      output = Pony.options
      output.should == input
    end
  end

end
