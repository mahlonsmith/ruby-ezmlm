#!/usr/bin/ruby


$LOAD_PATH.unshift( 'lib' )

begin
	require 'ezmlm'

rescue Exception => e
	$stderr.puts "Ack! Ezmlm libraries failed to load: #{e.message}\n\t" +
		e.backtrace.join( "\n\t" )
end


