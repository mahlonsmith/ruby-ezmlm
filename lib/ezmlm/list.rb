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
require 'ezmlm'
require 'mail'


### A Ruby interface to an ezmlm-idx mailing list directory
###
class Ezmlm::List

	### Create a new Ezmlm::List object for the specified +listdir+, which should be
	### an ezmlm-idx mailing list directory.
	###
	def initialize( listdir )
		listdir = Pathname.new( listdir ) unless listdir.is_a?( Pathname )
		@listdir = listdir
	end


	######
	public
	######

	# The Pathname object for the list directory
	attr_reader :listdir


	### Return the configured name of the list (without the host)
	def name
		return self.config[ 'L' ]
	end


	### Return the configured host of the list
	def host
		return self.config[ 'H' ]
	end


	### Return the configured address of the list (in list@host form)
	def address
		return "%s@%s" % [ self.name, self.host ]
	end
	alias_method :fullname, :address


	### Return the number of messages in the list archive
	def message_count
		numfile = self.listdir + 'num'
		return 0 unless numfile.exist?
		return Integer( numfile.read[/^(\d+):/, 1] )
	end


	### Return the Date parsed from the last post to the list.
	def last_message_date
		mail = self.last_post or return nil
		return mail.date
	end


	### Return the author of the last post to the list.
	def last_message_author
		mail = self.last_post or return nil
		return mail.from
	end


	### Return the list config as a Hash
	def config
		unless @config
			configfile = self.listdir + 'config'
			raise "List config file %p does not exist" % [ configfile ] unless configfile.exist?

			@config = configfile.read.scan( /^(\S):([^\n]*)$/m ).inject({}) do |h,pair|
				key,val = *pair
				h[key] = val
				h
			end
		end

		return @config
	end


	### Return the email address of the list's owner.
	def owner
		self.config['5']
	end


	### Fetch an Array of the email addresses for all of the list's subscribers.
	def subscribers
		subscribers_dir = self.listdir + 'subscribers'
		return self.read_subscriber_dir( subscribers_dir )
	end


	### Returns +true+ if subscription to the list is moderated.
	def closed?
		return (self.listdir + 'modsub').exist? || (self.listdir + 'remote').exist?
	end


	### Returns +true+ if posting to the list is moderated.
	def moderated?
		return (self.listdir + 'modpost').exist?
	end


	### Returns an Array of email addresses of people responsible for moderating subscription
	### of a closed list.
	def subscription_moderators
		return [] unless self.closed?

		modsubfile = self.listdir + 'modsub'
		remotefile = self.listdir + 'remote'

		subdir = nil
		if modsubfile.exist? && modsubfile.read(1) == '/'
			subdir = Pathname.new( modsubfile.read.chomp )
		elsif remotefile.exist? && remotefile.read(1) == '/'
			subdir = Pathname.new( remotefile.read.chomp )
		else
			subdir = self.listdir + 'mod/subscribers'
		end

		return self.read_subscriber_dir( subdir )
	end


	### Returns an Array of email addresses of people responsible for moderating posts
	### sent to the list.
	def message_moderators
		return [] unless self.moderated?

		modpostfile = self.listdir + 'modpost'
		subdir = nil

		if modpostfile.exist? && modpostfile.read(1) == '/'
			subdir = Pathname.new( modpostfile.read.chomp )
		else
			subdir = self.listdir + 'mod/subscribers'
		end

		return self.read_subscriber_dir( subdir )
	end


	### Return a TMail::Mail object loaded from the last post to the list. Returns
	### +nil+ if there are no archived posts.
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

		last_post = TMail::Mail.load( last_post_path.to_s )
	end



	#########
	protected
	#########

	### Read the hashed subscriber email addresses from the specified +directory+ and return them in
	### an Array.
	def read_subscriber_dir( directory )
		rval = []
		Pathname.glob( directory + '*' ) do |hashfile|
			rval.push( hashfile.read.scan(/T([^\0]+)\0/) )
		end

		return rval.flatten
	end

end # class Ezmlm::List

