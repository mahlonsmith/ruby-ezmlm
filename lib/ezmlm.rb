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
	require 'ezmlm/listdaemon'
	

	###############
	module_function
	###############

	### Find all directories that look like an Ezmlm list directory under the specified +listsdir+
	### and return Pathname objects for each.
	def find_directories( listsdir )
		listsdir = Pathname.new( listsdir )
		return Pathname.glob( listsdir + '*' ).select do |entry|
			entry.directory? && ( entry + 'mailinglist' ).exist?
		end
	end
	

	### Iterate over each directory that looks like an Ezmlm list in the specified +listsdir+ and
	### yield it as an Ezmlm::List object.
	def each_list( listsdir )
		find_directories( listsdir ).each do |entry|
			yield( Ezmlm::List.new(entry) )
		end
	end
	

end # module Ezmlm

# vim: set nosta noet ts=4 sw=4:
