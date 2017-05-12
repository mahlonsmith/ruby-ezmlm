#!/usr/bin/env ruby
#
# This script delivers a pile-o-test email to a local list.
#
# ** The list should first be configured to deliver to an additional
# Maildir. **
#
# After an initial delivery run, you can generate test replies.
#

require 'mail'
require 'faker'
require 'pathname'

abort "Usage: #{$0} send <listaddress> <message count>\n" +
	"       #{$0} reply </path/to/maildir> <message count>" if ARGV.size < 3
mode, list, count = ARGV

SENDERS = count.to_i.times.each_with_object( [] ) do |i, acc|
	acc << "%s %s <%s>" % [
		Faker::Name.first_name,
		Faker::Name.last_name,
		Faker::Internet.safe_email
	]
end

SUBJECTS = count.to_i.times.each_with_object( [] ) do |i, acc|
	intro = if rand(3).zero?
		"%s %s" % [
			[ 'Trying to', 'How do I', 'Help -' ].sample,
			Faker::Hacker.verb
		]
	else
		Faker::Hacker.ingverb.capitalize
	end
	acc << "%s %s %s %s%s" % [
		intro,
		( rand(2).zero? ? Faker::Hacker.noun : Faker::Hacker.abbreviation ),
		[ 'for a', 'on', 'on the', 'with some' ].sample,
		Faker::Hacker.noun,
		[ '?', '.', '?????'].sample
	]
end

Mail.defaults { delivery_method :sendmail }

case mode
	when 'send'
		until SENDERS.empty?
			mail = Mail.new do
				to      list
				from    SENDERS.pop
				subject SUBJECTS.pop
				body    Faker::Hacker.say_something_smart
			end
			mail.deliver
		end

	when 'reply'
		maildir = Pathname.new( list ) + 'new'
		abort "%s doesn't exist." unless maildir.exist?

		count.to_i.times do
			orig = Mail.read( maildir.children.sample.to_s )
			mail = Mail.new do
				to          orig.to
				from        SENDERS.sample
				subject     "Re: %s" % [ orig.subject ]
				body        Faker::Hacker.say_something_smart
				in_reply_to "<%s>" % [ orig.message_id ]
				references  "<%s>" % [ orig.message_id ]
			end
			mail.deliver
		end
end

