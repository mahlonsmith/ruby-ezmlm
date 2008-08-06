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

	TEST_LISTSDIR = '/tmp/lists'

	it "can fetch a list of all mailing list subdirectories beneath a given directory" do
		file_entry = mock( "plain file" )
		file_entry.should_receive( :directory? ).and_return( false )

		nonexistant_mlentry = stub( "mailinglist path that doesn't exist", :exist? => false )
		nonml_dir_entry = stub( "directory with no mailinglist file",
		 	:directory? => true, :+ => nonexistant_mlentry )

		existant_mlentry = stub( "mailinglist path that does exist", :exist? => true )
		ml_dir_entry = stub( "directory with a mailinglist file", :directory? => true, :+ => existant_mlentry )
		
		Pathname.should_receive( :glob ).with( an_instance_of(Pathname) ).
			and_return([ file_entry, nonml_dir_entry, ml_dir_entry ])

		dirs = Ezmlm.find_directories( TEST_LISTSDIR )
		
		dirs.should have(1).member
		dirs.should include( ml_dir_entry )
	end
	

	it "can iterate over all mailing lists in a specified directory" do
		Ezmlm.should_receive( :find_directories ).with( TEST_LISTSDIR ).and_return([ :listdir1, :listdir2 ])

		Ezmlm::List.should_receive( :new ).with( :listdir1 ).and_return( :listobject1 )
		Ezmlm::List.should_receive( :new ).with( :listdir2 ).and_return( :listobject2 )
		
		lists = []
		Ezmlm.each_list( TEST_LISTSDIR ) do |list|
			lists << list
		end
		
		lists.should have(2).members
		lists.should include( :listobject1, :listobject2 )
	end
	
end


