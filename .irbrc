#!/usr/bin/ruby -*- ruby -*-

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.expand_path
	libdir = basedir + "lib"

	puts ">>> Adding #{libdir} to load path..."
	$LOAD_PATH.unshift( libdir.to_s )

	require basedir + 'utils'
	include UtilityFunctions
}


# Try to require the 'thingfish' library
begin
	require 'ezmlm'
rescue => e
	$stderr.puts "Ack! Ezmlm library failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end

