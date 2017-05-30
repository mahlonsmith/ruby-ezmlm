# vim: set nosta noet ts=4 sw=4:

require 'pathname'

# A Ruby interface to the ezmlm-idx mailing list system.
#
#   Ezmlm.find_directories( '/lists' ) #=> [ Ezmlm::List, Ezmlm::List ]
#
#   Ezmlm.each_list( '/lists' ) do |list|
#       puts "\"%s\" <%s>" % [ list.name, list.address ]
#   end
#
module Ezmlm
	# $Id$

	# Package version
	VERSION = '1.1.1'

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
			entry.directory? && ( entry + 'ezmlmrc' ).exist?
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

