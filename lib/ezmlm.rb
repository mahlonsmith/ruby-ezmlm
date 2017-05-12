#!/usr/bin/ruby
# vim: set nosta noet ts=4 sw=4:
#
# A Ruby interface to the ezmlm-idx mailing list system.
#
# == Version
#
#  $Id$
#
#---
#
# Please see the file LICENSE in the base directory for licensing details.
#

require 'pathname'


### Toplevel namespace module
module Ezmlm

	# Package version
	VERSION = '0.1.0'

	# Suck in the components.
	#
	require 'ezmlm/hash'
	require 'ezmlm/list'
	require 'ezmlm/list/author'
	require 'ezmlm/list/message'
	require 'ezmlm/list/thread'


	###############
	module_function
	###############

	### Find all directories that look like an Ezmlm list directory under
	### the specified +listsdir+ and return Pathname objects for each.
	###
	def find_directories( listsdir )
		listsdir = Pathname.new( listsdir )
		return Pathname.glob( listsdir + '*' ).sort.select do |entry|
			entry.directory? && ( entry + 'mailinglist' ).exist?
		end
	end


	### Iterate over each directory that looks like an Ezmlm list in the
	### specified +listsdir+ and yield it as an Ezmlm::List object.
	###
	def each_list( listsdir )
		find_directories( listsdir ).each do |entry|
			yield( Ezmlm::List.new(entry) )
		end
	end

end # module Ezmlm

