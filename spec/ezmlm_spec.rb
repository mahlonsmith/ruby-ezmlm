#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec/runner'
	require 'spec/lib/helpers'
	require 'ezmlm'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


describe Ezmlm do
	include Ezmlm::SpecHelpers

	LISTSDIR = '/tmp/lists'

	it "can iterate over all mailing lists in a specified directory" do
		file_entry = mock( "plain file" )
		file_entry.should_receive( :directory? ).and_return( false )

		nonexistant_mlentry = stub( "mailinglist path that doesn't exist", :exist? => false )
		nonml_dir_entry = stub( "directory with no mailinglist file",
		 	:directory? => true, :+ => nonexistant_mlentry )

		existant_mlentry = stub( "mailinglist path that does exist", :exist? => true )
		ml_dir_entry = stub( "directory with a mailinglist file", :directory? => true, :+ => existant_mlentry )
		
		Pathname.should_receive( :glob ).with( an_instance_of(Pathname) ).
			and_yield( file_entry ).
			and_yield( nonml_dir_entry ).
			and_yield( ml_dir_entry )

		Ezmlm::List.should_receive( :new ).with( ml_dir_entry ).and_return( :listobject )
		
		lists = []
		Ezmlm.each_list( LISTSDIR ) do |list|
			lists << list
		end
		
		lists.should have(1).member
		lists.should include( :listobject )
	end
	
end


