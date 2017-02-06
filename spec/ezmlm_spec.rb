#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent
	libdir = basedir + "lib"
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require_relative 'spec_helpers'
require 'ezmlm'

describe Ezmlm do

	it "can fetch a list of all mailing list subdirectories beneath a given directory" do
		file_entry = double( "plain file" )
		expect( file_entry ).to receive( :directory? ).and_return( false )

		nonexistant_mlentry = double( "mailinglist path that doesn't exist", :exist? => false )
		nonml_dir_entry = double( "directory with no mailinglist file",
			:directory? => true, :+ => nonexistant_mlentry )

		existant_mlentry = double( "mailinglist path that does exist", :exist? => true )
		ml_dir_entry = double( "directory with a mailinglist file", :directory? => true, :+ => existant_mlentry )

		sorted_dirs = double( "sorted dirs" )
		expect( Pathname ).to receive( :glob ).with( an_instance_of(Pathname) ).
			and_return( sorted_dirs )
		expect( sorted_dirs ).to receive( :sort ).
			and_return([ file_entry, nonml_dir_entry, ml_dir_entry ])

		dirs = Ezmlm.find_directories( '/tmp' )

		expect( dirs.size ).to eq( 1 )
		expect( dirs ).to include( ml_dir_entry )
	end


	it "can iterate over all mailing lists in a specified directory" do
		expect( Ezmlm ).to receive( :find_directories ).with( '/tmp' ).and_return([ :listdir1, :listdir2 ])

		expect( Ezmlm::List ).to receive( :new ).with( :listdir1 ).and_return( :listobject1 )
		expect( Ezmlm::List ).to receive( :new ).with( :listdir2 ).and_return( :listobject2 )

		lists = []
		Ezmlm.each_list( '/tmp' ) do |list|
			lists << list
		end

		expect( lists.size ).to eq(2)
		expect( lists ).to include( :listobject1, :listobject2 )
	end
end


