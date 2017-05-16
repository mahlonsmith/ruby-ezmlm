#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:

require 'pathname'
require 'ezmlm' unless defined?( Ezmlm )


# A collection of messages authored from a unique user.
#
# Note that Ezmlm uses the "real name" part of an address
# to identify an author.
#
#    author = Ezmlm::List::Author.new( list, 'acgcbmbmeapgpfckcdol' )
#    author.name            #=> "Help - navigate on interface?"
#    author.first.date.to_s #=> "2017-05-07T14:55:05-07:00"
#
#---
class Ezmlm::List::Author
	#  $Id$
	include Enumerable

	### Instantiate a new list of messages given
	### a +list+ and an +author_id+.
	###
	def initialize( list, author_id )
		raise ArgumentError, "Unknown list object." unless list.respond_to?( :listdir )
		raise ArgumentError, "Malformed Author ID." unless author_id =~ /^\w{20}$/
		raise "Archiving is not enabled." unless list.archived?

		@list     = list
		@id       = author_id
		@messages = nil

		self.load_index
	end


	# The list object this message is stored in.
	attr_reader :list

	# The author's identifier.
	attr_reader :id

	# The author's name.
	attr_reader :name

	# An array of messages this author has sent.
	attr_reader :messages

	# An array of threads this author has participated in.
	attr_reader :threads


	### Enumerable API:  Lazy load each message ID as a
	### Ezmlm::List::Message, yielding it to the block.
	###
	def each
		self.load_index # refresh for any updates since object was created
		self.messages.each do |id|
			yield Ezmlm::List::Message.new( self.list, id )
		end
	end
	alias_method :each_message, :each


	### Lazy load each thread ID as a Ezmlm::List::Thread, yielding it to the block.
	###
	def each_thread
		self.load_index # refresh for any updates since object was created
		self.threads.each do |id|
			yield Ezmlm::List::Thread.new( self.list, id )
		end
	end


	#########
	protected
	#########

	### Parse the author index into an array of Messages.
	###
	def load_index
		@messages = []
		@threads  = []

		path = self.author_path
		raise "Unknown author: %p" % [ self.id ] unless path.exist?

		path.open( 'r', encoding: Encoding::ISO8859_1 ) do |fh|
			fh.each_line.with_index do |line, i|
				if i.zero?
					@name = line.match( /^\w+ (.+)/ )[1]
				else
					match = line.match( /^(\d+):\d+:(\w+) / ) or next
					self.messages << match[1].to_i
					self.threads  << match[2]
				end
			end
		end
	end


	### Return the path on disk for the author index.
	###
	def author_path
		prefix = self.id[ 0 ..  1 ]
		hash   = self.id[ 2 .. -1 ]
		return self.list.listdir + 'archive' + 'authors' + prefix + hash
	end

end # class Ezmlm::List::Author
