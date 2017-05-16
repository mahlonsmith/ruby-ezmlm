#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:


# A collection of messages for a specific archive thread.
#
#    thread = Ezmlm::List::Thread.new( list, 'acgcbmbmeapgpfckcdol' )
#    thread.subject         #=> "Help - navigate on interface?"
#    thread.first.date.to_s #=> "2017-05-07T14:55:05-07:00"
#
#
# == Version
#
#  $Id$
#
#---

require 'pathname'
require 'ezmlm' unless defined?( Ezmlm )


### A collection of messages for a specific archive thread.
###
class Ezmlm::List::Thread
	include Enumerable

	### Instantiate a new thread of messages given
	### a +list+ and a +thread_id+.
	###
	def initialize( list, thread_id )
		raise ArgumentError, "Unknown list object." unless list.respond_to?( :listdir )
		raise ArgumentError, "Malformed Thread ID." unless thread_id =~ /^\w{20}$/
		raise "Archiving is not enabled." unless list.archived?

		@list     = list
		@id       = thread_id
		@subject  = nil
		@messages = nil

		self.load_thread
	end


	# The list object this message is stored in.
	attr_reader :list

	# The thread's identifier.
	attr_reader :id

	# The subject line of the thread.
	attr_reader :subject

	# An array of member messages.
	attr_reader :messages

	# An array of member authors.
	attr_reader :authors


	### Enumerable API:  Lazy load each message ID as a
	### Ezmlm::List::Message, yielding it to the block.
	###
	def each
		self.load_thread # refresh for any thread updates since object was created
		self.messages.each do |id|
			yield Ezmlm::List::Message.new( self.list, id )
		end
	end
	alias_method :each_message, :each


	### Lazy load each author ID as a Ezmlm::List::Author, yielding it
	### to the block.
	###
	def each_author
		self.load_thread # refresh for any thread updates since object was created
		self.authors.each do |id|
			yield Ezmlm::List::Author.new( self.list, id )
		end
	end


	#########
	protected
	#########

	### Parse the subject index into an array of Messages.
	###
	def load_thread
		@messages = []
		@authors  = []
		path = self.thread_path
		raise "Unknown thread: %p" % [ self.id ] unless path.exist?

		path.open( 'r', encoding: Encoding::ISO8859_1 ) do |fh|
			fh.each_line.with_index do |line, i|
				if i.zero?
					@subject = line.match( /^\w+ (.+)/ )[1]
				else
					match = line.match( /^(\d+):\d+:(\w+) / ) or next
					self.messages << match[1].to_i
					self.authors  << match[2]
				end
			end
		end
	end


	### Return the path on disk for the thread index.
	###
	def thread_path
		prefix = self.id[ 0 ..  1 ]
		hash   = self.id[ 2 .. -1 ]
		return self.list.listdir + 'archive' + 'subjects' + prefix + hash
	end

end # class Ezmlm::List::Thread
