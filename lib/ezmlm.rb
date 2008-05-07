#!/usr/bin/ruby
#
# A Ruby programmatic interface to the ezmlm-idx mailing list system
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


### Toplevel namespace module
module Ezmlm

	# SVN Revision
	SVNRev = %q$Rev$

	# SVN Id
	SVNId = %q$Id$

	# Package version
	VERSION = '0.0.1'


	require 'ezmlm/list'
	
	

	###############
	module_function
	###############


	### Iterate over each directory that looks like an Ezmlm list in the specified +listsdir+ and
	### yield it as an Ezmlm::List object.
	def each_list( listsdir )
		listsdir = Pathname.new( listsdir )
		Pathname.glob( listsdir + '*' ) do |entry|
			next unless entry.directory?
			next unless ( entry + 'mailinglist' ).exist?

			yield( Ezmlm::List.new(entry) )
		end
	end
	

end # module Ezmlm

# vim: set nosta noet ts=4 sw=4:
