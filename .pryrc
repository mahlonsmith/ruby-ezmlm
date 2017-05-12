#!/usr/bin/ruby


$LOAD_PATH.unshift( 'lib' )

require 'pathname'
listpath = Pathname.new( __FILE__ ).dirname + 'spec' + 'data'

begin
	require 'ezmlm'
	list = Ezmlm::List.new( listpath + 'testlist' )

rescue Exception => e
	$stderr.puts "Ack! Ezmlm libraries failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end


