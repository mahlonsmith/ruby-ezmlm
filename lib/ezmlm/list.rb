#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:


require 'pathname'
require 'time'
require 'etc'
require 'ezmlm' unless defined?( Ezmlm )


# A Ruby interface to a single Ezmlm-idx mailing list directory.
#
#    list = Ezmlm::List.new( '/path/to/listdir' )
#
#---
class Ezmlm::List
	#  $Id$

	# Valid subdirectories/sections for subscriptions.
	SUBSCRIPTION_DIRS = %w[ deny mod digest allow ]


	### Create a new Ezmlm::List object for the specified +listdir+, which should be
	### an ezmlm-idx mailing list directory.
	###
	def initialize( listdir )
		listdir = Pathname.new( listdir ) unless listdir.is_a?( Pathname )
		unless listdir.directory? && ( listdir + 'mailinglist' ).exist?
			raise ArgumentError, "%p doesn't appear to be an ezmlm-idx list." % [ listdir.to_s ]
		end
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


	### Returns +true+ if +address+ is a subscriber to this list.
	###
	def include?( addr, section: nil )
		addr.downcase!
		file = self.subscription_dir( section ) + Ezmlm::Hash.subscriber( addr )
		return false unless file.exist?
		return file.read.scan( /T([^\0]+)\0/ ).flatten.include?( addr )
	end
	alias_method :is_subscriber?, :include?


	### Fetch a sorted Array of the email addresses for all of the list's
	### subscribers.
	###
	def subscribers
		return self.read_subscriber_dir
	end


	### Subscribe +addr+ to the list within +section+.
	###
	def subscribe( *addr, section: nil )
		addr.each do |address|
			next unless address.index( '@' )
			address.downcase!

			file = self.subscription_dir( section ) + Ezmlm::Hash.subscriber( address )
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
	alias_method :add_subscriber, :subscribe


	### Unsubscribe +addr+ from the list within +section+.
	###
	def unsubscribe( *addr, section: nil )
		addr.each do |address|
			address.downcase!

			file = self.subscription_dir( section ) + Ezmlm::Hash.subscriber( address )
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
	alias_method :remove_subscriber, :unsubscribe


	### Returns an Array of email addresses of people responsible for
	### moderating subscription of a closed list.
	###
	def moderators
		return self.read_subscriber_dir( 'mod' )
	end

	### Returns +true+ if +address+ is a moderator.
	###
	def is_moderator?( addr )
		return self.include?( addr, section: 'mod' )
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


	### Returns an Array of email addresses denied access
	### to the list.
	###
	def blacklisted
		return self.read_subscriber_dir( 'deny' )
	end

	### Returns +true+ if +address+ is disallowed from participating.
	###
	def is_blacklisted?( addr )
		return self.include?( addr, section: 'deny' )
	end

	### Blacklist +addr+ from the list.
	###
	def add_blacklisted( *addr )
		return self.subscribe( *addr, section: 'deny' )
	end

	### Remove +addr+ from the blacklist.
	###
	def remove_blacklisted( *addr )
		return self.unsubscribe( *addr, section: 'deny' )
	end



	### Returns an Array of email addresses that act like
	### regular subscribers for user-post only lists.
	###
	def allowed
		return self.read_subscriber_dir( 'allow' )
	end

	### Returns +true+ if +address+ is given the same benefits as a
	### regular subscriber for user-post only lists.
	###
	def is_allowed?( addr )
		return self.include?( addr, section: 'allow' )
	end

	### Add +addr+ to allow posting to user-post only lists,
	### when +addr+ isn't a subscriber.
	###
	def add_allowed( *addr )
		return self.subscribe( *addr, section: 'allow' )
	end

	### Remove +addr+ from the allowed list.
	###
	def remove_allowed( *addr )
		return self.unsubscribe( *addr, section: 'allow' )
	end


	### Returns +true+ if the list is configured to respond
	### to remote management requests.
	###
	def public?
		return ( self.listdir + 'public' ).exist?
	end

	### Disable or enable remote management requests.
	###
	def public=( enable=true )
		if enable
			self.touch( 'public' )
		else
			self.unlink( 'public' )
		end
	end
	alias_method :public, :public=

	### Returns +true+ if the list is not configured to respond
	### to remote management requests.
	###
	def private?
		return ! self.public?
	end

	### Disable or enable remote management requests.
	###
	def private=( enable=false )
		self.public = ! enable
	end
	alias_method :private, :private=


	### Returns +true+ if the list supports remote administration
	### subscribe/unsubscribe requests from moderators.
	###
	def remote_subscriptions?
		return ( self.listdir + 'remote' ).exist?
	end

	### Disable or enable remote subscription requests.
	###
	def remote_subscriptions=( enable=false )
		if enable
			self.touch( 'remote' )
		else
			self.unlink( 'remote' )
		end
	end
	alias_method :remote_subscriptions, :remote_subscriptions=


	### Returns +true+ if list subscription requests require moderator
	### approval.
	###
	def moderated_subscriptions?
		return ( self.listdir + 'modsub' ).exist?
	end

	### Disable or enable subscription moderation.
	###
	def moderated_subscriptions=( enable=false )
		if enable
			self.touch( 'modsub' )
		else
			self.unlink( 'modsub' )
		end
	end
	alias_method :moderated_subscriptions, :moderated_subscriptions=

	### Returns +true+ if message moderation is enabled.
	###
	def moderated?
		return ( self.listdir + 'modpost' ).exist?
	end

	### Disable or enable message moderation.
	###
	### This has special meaning when combined with user_posts_only setting.
	### Lists act as unmoderated for subscribers, and posts from unknown
	### addresses go to moderation.
	###
	def moderated=( enable=false )
		if enable
			self.touch( 'modpost' )
			self.touch( 'noreturnposts' ) if self.user_posts_only?
		else
			self.unlink( 'modpost' )
			self.unlink( 'noreturnposts' ) if self.user_posts_only?
		end
	end
	alias_method :moderated, :moderated=


	### Returns +true+ if posting is only allowed by moderators.
	###
	def moderator_posts_only?
		return ( self.listdir + 'modpostonly' ).exist?
	end

	### Disable or enable moderation only posts.
	###
	def moderator_posts_only=( enable=false )
		if enable
			self.touch( 'modpostonly' )
		else
			self.unlink( 'modpostonly' )
		end
	end
	alias_method :moderator_posts_only, :moderator_posts_only=


	### Returns +true+ if posting is only allowed by subscribers.
	###
	def user_posts_only?
		return ( self.listdir + 'subpostonly' ).exist?
	end

	### Disable or enable user only posts.
	### This is easily defeated, moderated lists are preferred.
	###
	### This has special meaning for moderated lists.  Lists act as
	### unmoderated for subscribers, and posts from unknown addresses
	### go to moderation.
	###
	def user_posts_only=( enable=false )
		if enable
			self.touch( 'subpostonly' )
			self.touch( 'noreturnposts' )if self.moderated?
		else
			self.unlink( 'subpostonly' )
			self.unlink( 'noreturnposts' ) if self.moderated?
		end
	end
	alias_method :user_posts_only, :user_posts_only=


	### Returns +true+ if message archival is enabled.
	###
	def archived?
		test = %w[ archived indexed threaded ].each_with_object( [] ) do |f, acc|
			acc << self.listdir + f
		end

		return test.all?( &:exist? )
	end

	### Disable or enable message archiving (and indexing/threading.)
	###
	def archived=( enable=true )
		if enable
			self.touch( 'archived', 'indexed', 'threaded' )
		else
			self.unlink( 'archived', 'indexed', 'threaded' )
		end
	end
	alias_method :archived, :archived=

	### Returns +true+ if the message archive is accessible only to
	### moderators.
	###
	def private_archive?
		return ( self.listdir + 'modgetonly' ).exist?
	end

	### Disable or enable private access to the archive.
	###
	def private_archive=( enable=true )
		if enable
			self.touch( 'modgetonly' )
		else
			self.unlink( 'modgetonly' )
		end
	end
	alias_method :private_archive, :private_archive=

	### Returns +true+ if the message archive is accessible to anyone.
	###
	def public_archive?
		return ! self.private_archive?
	end

	### Disable or enable private access to the archive.
	###
	def public_archive=( enable=true )
		self.private_archive = ! enable
	end
	alias_method :public_archive, :public_archive=

	### Returns +true+ if the message archive is accessible only to
	### list subscribers.
	###
	def guarded_archive?
		return ( self.listdir + 'subgetonly' ).exist?
	end

	### Disable or enable loimited access to the archive.
	###
	def guarded_archive=( enable=true )
		if enable
			self.touch( 'subgetonly' )
		else
			self.unlink( 'subgetonly' )
		end
	end
	alias_method :guarded_archive, :guarded_archive=


	### Returns +true+ if message digests are enabled.
	###
	def digested?
		return ( self.listdir + 'digested' ).exist?
	end

	### Disable or enable message digesting.
	###
	def digest=( enable=true )
		if enable
			self.touch( 'digested' )
		else
			self.unlink( 'digested' )
		end
	end
	alias_method :digest, :digest=

	### If the list is digestable, trigger the digest after this amount
	### of message body since the latest digest, in kbytes.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_kbytesize
		size = self.read( 'digsize' ).to_i
		return size.zero? ? 64 : size
	end

	### If the list is digestable, trigger the digest after this amount
	### of message body since the latest digest, in kbytes.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_kbytesize=( size=64 )
		self.write( 'digsize' ) {|f| f.puts size.to_i }
	end

	### If the list is digestable, trigger the digest after this many
	### messages have accumulated since the latest digest.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_count
		count = self.read( 'digcount' ).to_i
		return count.zero? ? 30 : count
	end

	### If the list is digestable, trigger the digest after this many
	### messages have accumulated since the latest digest.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_count=( count=30 )
		self.write( 'digcount' ) {|f| f.puts count.to_i }
	end

	### If the list is digestable, trigger the digest after this much
	### time has passed since the last digest, in hours.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_timeout
		hours = self.read( 'digtime' ).to_i
		return hours.zero? ? 48 : hours
	end

	### If the list is digestable, trigger the digest after this much
	### time has passed since the last digest, in hours.
	###
	### See: ezmlm-tstdig(1)
	###
	def digest_timeout=( hours=48 )
		self.write( 'digtime' ) {|f| f.puts hours.to_i }
	end


	### Returns +true+ if the list requires subscriptions to be
	### confirmed.  AKA "help" mode if disabled.
	###
	def confirm_subscriptions?
		return ! ( self.listdir + 'nosubconfirm' ).exist?
	end

	### Disable or enable subscription confirmation.
	### AKA "help" mode if disabled.
	###
	def confirm_subscriptions=( enable=true )
		if enable
			self.unlink( 'nosubconfirm' )
		else
			self.touch( 'nosubconfirm' )
		end
	end
	alias_method :confirm_subscriptions, :confirm_subscriptions=

	### Returns +true+ if the list requires unsubscriptions to be
	### confirmed.  AKA "jump" mode.
	###
	def confirm_unsubscriptions?
		return ! ( self.listdir + 'nounsubconfirm' ).exist?
	end

	### Disable or enable unsubscription confirmation.
	### AKA "jump" mode.
	###
	def confirm_unsubscriptions=( enable=true )
		if enable
			self.unlink( 'nounsubconfirm' )
		else
			self.touch( 'nounsubconfirm' )
		end
	end
	alias_method :confirm_unsubscriptions, :confirm_unsubscriptions=


	### Returns +true+ if the list requires regular message postings
	### to be confirmed by the original sender.
	###
	def confirm_postings?
		return ( self.listdir + 'confirmpost' ).exist?
	end

	### Disable or enable message confirmation.
	###
	def confirm_postings=( enable=false )
		if enable
			self.touch( 'confirmpost' )
		else
			self.unlink( 'confirmpost' )
		end
	end
	alias_method :confirm_postings, :confirm_postings=


	### Returns +true+ if the list allows moderators to
	### fetch a subscriber list remotely.
	###
	def allow_remote_listing?
		return ( self.listdir + 'modcanlist' ).exist?
	end

	### Disable or enable the ability for moderators to
	### remotely fetch a subscriber list.
	###
	def allow_remote_listing=( enable=false )
		if enable
			self.touch( 'modcanlist' )
		else
			self.unlink( 'modcanlist' )
		end
	end
	alias_method :allow_remote_listing, :allow_remote_listing=


	### Returns +true+ if the list automatically manages
	### bouncing subscriber addresses.
	###
	def bounce_warnings?
		return ! ( self.listdir + 'nowarn' ).exist?
	end

	### Disable or enable automatic bounce probes and warnings.
	###
	def bounce_warnings=( enable=true )
		if enable
			self.unlink( 'nowarn' )
		else
			self.touch( 'nowarn' )
		end
	end
	alias_method :bounce_warnings, :bounce_warnings=


	### Return the maximum message size, in bytes.  Messages larger than
	### this size will be rejected.
	###
	### See: ezmlm-reject(1)
	###
	def maximum_message_size
		size = self.read( 'msgsize' )
		return size ? size.split( ':' ).first.to_i : 0
	end

	### Set the maximum message size, in bytes.  Messages larger than
	### this size will be rejected.  Defaults to 300kb.
	###
	### See: ezmlm-reject(1)
	###
	def maximum_message_size=( size=307200 )
		if size.to_i.zero?
			self.unlink( 'msgsize' )
		else
			self.write( 'msgsize' ) {|f| f.puts "#{size.to_i}:0" }
		end
	end



	### Return the number of messages in the list archive.
	###
	def message_count
		count = self.read( 'archnum' )
		return count ? Integer( count ) : 0
	end

	### Returns an individual message if archiving was enabled.
	###
	def message( message_id )
		raise "Message archive is empty." if self.message_count.zero?
		return Ezmlm::List::Message.new( self, message_id ) rescue nil
	end

	### Lazy load each message ID as a Ezmlm::List::Message,
	### yielding it to the block.
	###
	def each_message
		( 1 .. self.message_count ).each do |id|
			yield self.message( id )
		end
	end


	### Return a Thread object for the given +thread_id+.
	###
	def thread( thread_id )
		return Ezmlm::List::Thread.new( self, thread_id ) rescue nil
	end


	### Return an Author object for the given +author_id+, which
	### could also be an email address.
	###
	def author( author_id )
		author_id = Ezmlm::Hash.address(author_id) if author_id.index( '@' )
		return Ezmlm::List::Author.new( self, author_id ) rescue nil
	end


	### Return a Time object for the last activity on the list, or nil
	### if archiving is disabled or there are no posts.
	###
	def last_activity
		file = self.listdir + 'archnum'
		return unless file.exist?
		return file.stat.mtime
	end


	### Parse all thread indexes into a single array that can be used
	### as a lookup table.
	###
	### These are not expanded into objects, use #message, #thread,
	### and #author to do so.
	###
	def index
		raise "Archiving is not enabled." unless self.archived?
		archivedir = listdir + 'archive'

		idx = ( 0 .. self.message_count / 100 ).each_with_object( [] ) do |dir, acc|
			index = archivedir + dir.to_s + 'index'
			next unless index.exist?

			index.open( 'r', encoding: Encoding::ISO8859_1 ) do |fh|
				fh.each_line.lazy.slice_before( /^\d+:/ ).each do |message|

					match = message[0].match( /^(?<message_id>\d+): (?<thread_id>\w+)/ )
					next unless match
					thread_id  = match[ :thread_id ]

					match = message[1].match( /^(?<date>[^;]+);(?<author_id>\w+) / )
					next unless match
					author_id  = match[ :author_id ]
					date       = match[ :date ]

					metadata = {
						date:   Time.parse( date ),
						thread: thread_id,
						author: author_id
					}
					acc << metadata
				end
			end
		end

		return idx
	end


	#########
	protected
	#########

	### Just return the contents of the provided +file+, rooted
	### in the list directory.
	###
	def read( file )
		file = self.listdir + file unless file.is_a?( Pathname )
		return file.read.chomp
	rescue
		nil
	end


	### Overwrite +file+ safely, yielding the open filehandle to the
	### block.  Set the new file to correct ownership and permissions.
	###
	def write( file, &block )
		file = self.listdir + file unless file.is_a?( Pathname )
		self.with_safety do
			file.open( 'w' ) do |f|
				yield( f )
			end

			stat = self.listdir.stat
			file.chown( stat.uid, stat.gid )
			file.chmod( 0600 )
		end
	end


	### Simply create an empty file, safely.
	###
	def touch( *file )
		self.with_safety do
			Array( file ).flatten.each do |f|
				f = self.listdir + f unless f.is_a?( Pathname )
				f.open( 'w' ) {}
			end
		end
	end


	### Delete +file+ safely.
	###
	def unlink( *file )
		self.with_safety do
			Array( file ).flatten.each do |f|
				f = self.listdir + f unless f.is_a?( Pathname )
				next unless f.exist?
				f.unlink
			end
		end
	end


	### Return a Pathname to a subscription directory.
	###
	def subscription_dir( section=nil )
		if section
			unless SUBSCRIPTION_DIRS.include?( section )
				raise "Invalid subscription dir: %s, must be one of: %s" % [
					section,
					SUBSCRIPTION_DIRS.join( ', ' )
				]
			end
			return self.listdir + section + 'subscribers'
		else
			return self.listdir + 'subscribers'
		end
	end


	### Read the hashed subscriber email addresses from the specified
	### +directory+ and return them in an Array.
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

