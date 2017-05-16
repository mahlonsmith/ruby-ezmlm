#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:

require 'pathname'
require 'ezmlm' unless defined?( Ezmlm )
require 'mail'

# An individual list message.
#
#    message = Ezmlm::List::Message.new( list, 24 )
#    message.thread    #=> (a thread object this message is part of)
#    message.from      #=> ["jalon.hermann@example.com"]
#    puts message.to_s #=> (raw email)
#
# This class passes all heavy lifting to the Mail::Message library.
# Please see it for specifics on usage.
#
#---
class Ezmlm::List::Message
	#  $Id$

	### Instantiate a new messag from a +list+ and a +message_number+.
	###
	def initialize( list, message_number=0 )
		raise ArgumentError, "Unknown list object." unless list.respond_to?( :listdir )
		raise ArgumentError, "Invalid message number (impossible)" if message_number < 1
		raise "Archiving is not enabled." unless list.archived?
		raise ArgumentError, "Invalid message number (out of list bounds)" if message_number > list.message_count

		@list = list
		@id   = message_number
		@post = self.load_message
	end


	# The list object this message is stored in.
	attr_reader :list

	# The list message delivery identifier.
	attr_reader :id

	# The Mail::Message object for this post.
	attr_reader :post


	### Return the thread object this message is
	### a member of.
	###
	def thread
		unless @thread_id
			idx = self.list.index
			@thread_id = idx[ self.id - 1 ][ :thread ]
		end

		return Ezmlm::List::Thread.new( self.list, @thread_id )
	end


	### Return the author object this message is
	### a member of.
	###
	def author
		unless @author_id
			idx = self.list.index
			@author_id = idx[ self.id - 1 ][ :author ]
		end

		return Ezmlm::List::Author.new( self.list, @author_id )
	end


	### Render the message as a string.
	###
	def to_s
		return self.post.to_s
	end

	### Provide implicit arrays (Mail::Message does not.)
	###
	def to_ary
		return [ self.post ]
	end


	### Pass all unknown methods to the underlying Mail::Message object.
	###
	def method_missing( meth, *args )
		return self.post.method( meth ).call( *args )
	end


	#########
	protected
	#########

	### Parse the message into a Mail::Message.
	###
	def load_message
		path = self.message_path
		raise "Unable to determine message path: %p" % [ path ] unless path.exist?
		return Mail.read( path.to_s )
	end


	### Return the path on disk for the message.
	###
	def message_path
		hashdir = self.id / 100
		message = "%02d" % [ self.id % 100 ]
		return self.list.listdir + 'archive' + hashdir.to_s + message.to_s
	end

end # class Ezmlm::List::Message
