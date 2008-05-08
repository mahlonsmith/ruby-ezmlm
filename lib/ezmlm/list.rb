#!/usr/bin/ruby
#
# A Ruby interface to a single Ezmlm-idx mailing list directory
#
# == Version
#
#  $Id$
#
# == Authors
#
# * Michael Granger <mgranger@laika.com>
# * Jeremiah Jordan <jjordan@laika.com>
#
# :include: LICENSE
# 
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#

require 'pathname'
require 'ezmlm'


### A Ruby interface to an ezmlm-idx mailing list directory
class Ezmlm::List
	
	### Create a new Ezmlm::List object for the specified +listdir+, which should be
	### an ezmlm-idx mailing list directory.
	def initialize( listdir )
		listdir = Pathname.new( listdir ) if !listdir.is_a?( Pathname )
		@listdir = listdir
	end


	######
	public
	######

	# The Pathname object for the list directory
	attr_reader :listdir


	### Return the email address of the list's owner.
	def owner
		config = self.listdir + 'config'
		if config.read =~ /^5:([^\n]+)$/m
			return $1
		else
			return nil
		end
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
	
	
end

# vim: set nosta noet ts=4 sw=4:
