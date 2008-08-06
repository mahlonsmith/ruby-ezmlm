#!/usr/bin/ruby
#
# A DRb interface to one or more ezmlm-idx mailing lists.
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
require 'ezmlm/list'
require 'drb'
require 'ostruct'


### A DRb interface to one or more ezmlm-idx mailing lists
class Ezmlm::ListDaemon
	
	# The default port to listen on
	DEFAULT_PORT = 32315
	
	# The default address to bind to
	DEFAULT_ADDRESS = '127.0.0.1'
	
	
	### The interface that is presented to DRb
	class Service
		include Enumerable
		
		### Create a new service endpoint for the specified +listsdir+, which is a directory
		### which contains ezmlm-idx list directories.
		def initialize( listsdir )
			listsdir = Pathname.new( listsdir )
			@listsdir = listsdir
		end


		######
		public
		######

		# The directory which contains the list directories that should be served.
		attr_reader :listsdir
		
		
		### Create a new Ezmlm::List object for the list directory with the specified +name+.
		def get_list( name )
			name = validate_listdir_name( name )
			return Ezmlm::List.new( self.listsdir + name )
		end


		### Iterate over each current list in the Service's listsdir, yielding an Ezmlm::List object
		### for each one.
		def each_list( &block ) # :yields: list_object
			Ezmlm.each_list( self.listsdir, &block )
		end
		alias_method :each, :each_list
		

		#######
		private
		#######

		VALID_LISTNAME_PATTERN = /^[a-z0-9.-]+$/i

		### Ensure that the given +name+ is a valid list name, raising an exception if not. Returns
		### an untainted copy of +name+.
		def validate_listdir_name( name )
			unless match = VALID_LISTNAME_PATTERN.match( name )
				raise ArgumentError, "invalid list name %p" % [ name ]
			end
			
			return match[0].untaint
		end
		
	end # class Service
	
	

	### Return an OpenStruct that contains the default options
	def self::default_options
		opts = OpenStruct.new

		opts.bind_addr  = DEFAULT_ADDRESS
		opts.bind_port  = DEFAULT_PORT
		opts.debugmode  = false
		opts.helpmode   = false
		opts.foreground = false

		return opts
	end
	
	
	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new Ezmlm::ListDaemon that will serve objects for the list directories
	### contained in +listsdir+. The +options+ argument, if given, is an object (such as the one
	### returned from ::default_options) that contains values for the following methods:
	### 
	### bind_addr::
	###   The address to bind to. Defaults to DEFAULT_ADDRESS.
	### bind_port::
	###   The port to listen on. Defaults to DEFAULT_PORT.
	### debugmode:: 
	###   Whether to run in debugging mode, which causes the daemon to run in the foreground
	###   and send any output to STDERR. Defaults to +false+.
	### foreground::
	###   Don't go into the background.
	def initialize( listsdir, options=nil )
		@service = Service.new( listsdir )
		@options = options || self.class.default_options
	end


	######
	public
	######

	# The daemon's configuration options
	attr_reader :options
	
	# The Ezmlm::ListDaemon::Service object that serves as the DRb interface
	attr_reader :service


	### Daemonize unless configured otherwise, start the DRb service and return the listening 
	### Thread object
	def start
		uri = "druby://%s:%d" % [ self.options.bind_addr, self.options.bind_port ]
		DRb.start_service( uri, @service )
		
		return DRb.thread
	end
	

end # class Ezmlm::ListDaemon

# vim: set nosta noet ts=4 sw=4:
