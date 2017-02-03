#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:
#
# A Ruby interface to a single Ezmlm-idx mailing list directory.
#
# == Version
#
#  $Id$
#
#---

require 'pathname'
require 'etc'
require 'ezmlm'
require 'mail'


### A Ruby interface to an ezmlm-idx mailing list directory
###
class Ezmlm::List

	# Quick address space detection, to (hopefully)
	# match the overflow size on this machine.
	#
	ADDRESS_SPACE = case [ 'i' ].pack( 'p' ).size
					when 4
						32
					when 8
						64
					end

	# Valid subdirectories/sections for subscriptions.
	SUBSCRIPTION_DIRS = %w[ deny mod digest allow ]


	### Create a new Ezmlm::List object for the specified +listdir+, which should be
	### an ezmlm-idx mailing list directory.
	###
	def initialize( listdir )
		listdir = Pathname.new( listdir ) unless listdir.is_a?( Pathname )
		@listdir = listdir
	end

	# The Pathname object for the list directory
	attr_reader :listdir


	### Return the configured name of the list (without the host)
	###
	def name
		@name = self.read( 'outlocal' ) unless @name
		return @name
	end


	### Return the configured host of the list
	###
	def host
		@host = self.read( 'outhost' ) unless @host
		return @host
	end


	### Return the configured address of the list (in list@host form)
	###
	def address
		return "%s@%s" % [ self.name, self.host ]
	end
	alias_method :fullname, :address


	### Return the email address of the list's owner.
	###
	def owner
		owner = self.read( 'owner' )
		return owner =~ /@/ ? owner : nil
	end


	### Return the number of messages in the list archive.
	###
	def message_count
		count = self.read( 'archnum' )
		return count ? Integer( count ) : 0
	end


	### Fetch a sorted Array of the email addresses for all of the list's
	### subscribers.
	###
	def subscribers
		return self.read_subscriber_dir
	end


	### Returns an Array of email addresses of people responsible for
	### moderating subscription of a closed list.
	###
	def moderators
		return self.read_subscriber_dir( 'mod' )
	end


	### Subscribe +addr+ to the list as a Moderator.
	###
	def add_moderator( *addr )
		return self.subscribe( *addr, section: 'mod' )
	end


	### Remove +addr+ from the list as a Moderator.
	###
	def remove_moderator( *addr )
		return self.unsubscribe( *addr, section: 'mod' )
	end


	### Returns +true+ if +address+ is a subscriber to this list.
	###
	def include?( addr )
		addr.downcase!
		file = self.subscription_dir + self.hashchar( addr )
		return false unless file.exist?
		return file.read.scan( /T([^\0]+)\0/ ).flatten.include?( addr )
	end


	### Subscribe +addr+ to the list within +section+.
	###
	def subscribe( *addr, section: nil )
		addr.each do |address|
			next unless address.index( '@' )
			address.downcase!

			file = self.subscription_dir( section ) + self.hashchar( address )
			self.with_safety do
				if file.exist?
					addresses = file.read.scan( /T([^\0]+)\0/ ).flatten
					addresses << address
					file.open( 'w' ) do |f|
						f.print addresses.uniq.sort.map{|a| "T#{a}\0" }.join
					end

				else
					file.open( 'w' ) do |f|
						f.print "T%s\0" % [ address ]
					end
				end
			end
		end
	end


	### Unsubscribe +addr+ from the list within +section+.
	###
	def unsubscribe( *addr, section: nil )
		addr.each do |address|
			address.downcase!

			file = self.subscribers_dir( section ) + self.hashchar( address )
			self.with_safety do
				next unless file.exist?
				addresses = file.read.scan( /T([^\0]+)\0/ ).flatten
				addresses = addresses - [ address ]

				if addresses.empty?
					file.unlink
				else
					file.open( 'w' ) do |f|
						f.print addresses.uniq.sort.map{|a| "T#{a}\0" }.join
					end
				end
			end
		end
	end


=begin
	### Return the Date parsed from the last post to the list.
	###
	def last_message_date
		mail = self.last_post or return nil
		return mail.date
	end


	### Return the author of the last post to the list.
	###
	def last_message_author
		mail = self.last_post or return nil
		return mail.from
	end


	### Returns +true+ if subscription to the list is moderated.
	###
	def closed?
		return (self.listdir + 'modsub').exist? || (self.listdir + 'remote').exist?
	end


	### Returns +true+ if posting to the list is moderated.
	###
	def moderated?
		return (self.listdir + 'modpost').exist?
	end


	### Return a Mail::Message object loaded from the last post to the list. Returns
	### +nil+ if there are no archived posts.
	###
	def last_post
		archivedir = self.listdir + 'archive'
		return nil unless archivedir.exist?

		# Find the last numbered directory under the archive dir
		last_archdir = Pathname.glob( archivedir + '[0-9]*' ).
			sort_by {|pn| Integer(pn.basename.to_s) }.last

		return nil unless last_archdir

		# Find the last numbered file under the last numbered directory we found
		# above.
		last_post_path = Pathname.glob( last_archdir + '[0-9]*' ).
			sort_by {|pn| pn.basename.to_s }.last

		raise RuntimeError, "unexpectedly empty archive directory '%s'" % [ last_archdir ] \
			unless last_post_path

				require 'pry'
				binding.pry
		last_post = TMail::Mail.load( last_post_path.to_s )
	end
=end


	#########
	protected
	#########

	### Hash an email address, using the ezmlm algorithm for
	### fast user lookups.  Returns the hashed integer.
	###
	### Older ezmlm didn't lowercase addresses, anything within the last
	### decade did.  We're not going to worry about compatibility there.
	###
	### (See subhash.c in the ezmlm source.)
	###
	def subhash( addr )
		h = 5381
		over = 2 ** ADDRESS_SPACE

		addr = 'T' + addr
		addr.each_char do |c|
			h = ( h + ( h << 5 ) ) ^ c.ord
			h = h % over if h > over # emulate integer overflow
		end
		return h % 53
	end


	### Given an email address, return the ascii character.
	###
	def hashchar( addr )
		return ( self.subhash(addr) + 64 ).chr
	end


	### Just return the contents of the provided +file+, rooted
	### in the list directory.
	###
	def read( file )
		file = self.listdir + file unless file.is_a?( Pathname )
		return file.read.chomp
	rescue
		nil
	end


	### Return a Pathname to a subscription directory.
	###
	def subscription_dir( section=nil )
		section = nil if section && ! SUBSCRIPTION_DIRS.include?( section )

		if section
			return self.listdir + section + 'subscribers'
		else
			return self.listdir + 'subscribers'
		end
	end


	### Read the hashed subscriber email addresses from the specified +directory+ and return them in
	### an Array.
	###
	def read_subscriber_dir( section=nil )
		directory = self.subscription_dir( section )
		rval = []
		Pathname.glob( directory + '*' ) do |hashfile|
			rval.push( hashfile.read.scan(/T([^\0]+)\0/) )
		end

		return rval.flatten.sort
	end


	### Return a Pathname object for the list owner's home directory.
	###
	def homedir
		user = Etc.getpwuid( self.listdir.stat.uid )
		return Pathname( user.dir )
	end


	### Safely make modifications to a file within a list directory.
	###
	### Mail can come in at any time.  Make changes within a list
	### atomic -- if an incoming message hits when a sticky
	### is set, it is deferred to the Qmail queue.
	###
	###   - Set sticky bit on the list directory owner's homedir
	###   - Make changes with the block
	###   - Unset sticky (just back to what it was previously)
	###
	### All writes should be wrapped in this method.
	###
	def with_safety( &block )
		home = self.homedir
		mode = home.stat.mode

		home.chmod( mode | 01000 ) # enable sticky
		yield

	ensure
		home.chmod( mode )
	end

end # class Ezmlm::List

