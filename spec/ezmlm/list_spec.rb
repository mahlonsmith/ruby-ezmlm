#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}


begin
	require 'tmail'
	require 'spec/runner'
	require 'spec/lib/helpers'
	require 'ezmlm/list'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


describe Ezmlm::List do
	include Ezmlm::SpecHelpers


	# Testing constants
	TEST_LISTDIR               = Pathname.new( 'list' )
	TEST_LIST_NAME             = 'waffle-lovers'
	TEST_LIST_HOST             = 'lists.syrup.info'
	TEST_OWNER                 = 'listowner@rumpus-the-whale.info'
	TEST_CUSTOM_MODERATORS_DIR = '/foo/bar/clowns'
	
	TEST_SUBSCRIBERS = %w[
		pete.chaffee@toadsmackers.com
		dolphinzombie@alahalohamorra.com
		piratebanker@yahoo.com
	  ]

	TEST_MODERATORS = %w[
		dolphinzombie@alahalohamorra.com
	  ]
	
	TEST_CONFIG = <<-"EOF".gsub( /^\t+/, '' )
		F:-aBCDeFGHijKlMnOpQrStUVWXYZ
		X:
		D:/var/qmail/alias/lists/waffle-lovers/
		T:/var/qmail/alias/.qmail-waffle-lovers
		L:#{TEST_LIST_NAME}
		H:#{TEST_LIST_HOST}
		C:
		0:
		3:
		4:
		5:#{TEST_OWNER}
		6:
		7:
		8:
		9:
	EOF
	

	it "can create a list"
	it "can add a new subscriber"
	it "can remove a current subscriber"
	it "can edit the list's text files"


	### 
	### List manager functions
	### 
	describe "list manager functions" do
		
		before( :each ) do
			@listpath = TEST_LISTDIR.dup
			@list = Ezmlm::List.new( @listpath )
		end
		
		
		it "can return the configured list name" do
			@list.stub!( :config ).and_return({ 'L' => :the_list_name })
			@list.name.should == :the_list_name
		end
		
		
		it "can return the configured list host" do
			@list.stub!( :config ).and_return({ 'H' => :the_list_host })
			@list.host.should == :the_list_host
		end
		
		
		it "can return the configured list address" do
			@list.stub!( :config ).and_return({ 'L' => TEST_LIST_NAME, 'H' => TEST_LIST_HOST })
			@list.address.should == "%s@%s" % [ TEST_LIST_NAME, TEST_LIST_HOST ]
		end
		
		
		CONFIG_KEYS = %w[ F X D T L H C 0 3 4 5 6 7 8 9 ]

		it "can fetch the list config as a Hash" do
			config_path = mock( "Mock config path" )
			@listpath.should_receive( :+ ).with( 'config' ).and_return( config_path )
			config_path.should_receive( :exist? ).and_return( true )
			config_path.should_receive( :read ).and_return( TEST_CONFIG )
			
			@list.config.should be_an_instance_of( Hash )
			@list.config.should have( CONFIG_KEYS.length ).members
			@list.config.keys.should include( *CONFIG_KEYS )
		end

		
		it "raises an error if the list config file doesn't exist" do
			config_path = mock( "Mock config path" )
			@listpath.should_receive( :+ ).with( 'config' ).and_return( config_path )
			config_path.should_receive( :exist? ).and_return( false )

			lambda {
				@list.config
			}.should raise_error( RuntimeError, /does not exist/ )
		end

		
		it "can return a list of subscribers' email addresses" do
			subscribers_dir = TEST_LISTDIR + 'subscribers'
			
			expectation = Pathname.should_receive( :glob ).with( subscribers_dir + '*' )

			TEST_SUBSCRIBERS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end
				
			subscribers = @list.subscribers
			
			subscribers.should have(TEST_SUBSCRIBERS.length).members
			subscribers.should include( *TEST_SUBSCRIBERS )
		end


		### Subscriber moderation

		it "knows that subscription moderation is enabled if the dir/modsub file exists" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_closed()
		end
		
		it "knows that subscription moderation is enabled if the dir/remote file exists" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_closed()
		end
		
		
		it "knows that subscription moderation is disabled if neither the dir/modsub nor " +
		   "dir/remote files exist" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( false )

			@list.should_not be_closed()
		end


		it "returns an empty array of subscription moderators for an open list" do
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).and_return( false )

			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).and_return( false )

			@list.subscription_moderators.should be_empty()
		end
	
		it "can return a list of subscription moderators' email addresses" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( true )
			remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			remote_path_obj.should_receive( :exist? ).once.and_return( true )

			# Try to read directory names from both config files
			modsub_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			remote_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			
			# Read subscribers from the default directory
			subscribers_dir = mock( "Mock moderator subscribers directory" )
			@listpath.should_receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			subscribers_dir.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		
		it "can return a list of subscription moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( true )
			@listpath.should_receive( :+ ).with( 'remote' )

			# Try to read directory names from both config files
			modsub_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			modsub_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		it "can get a list of modererators when remote subscription moderation is enabled" +
           " and the modsub configuration is empty" do
			# Test the moderation config files for existence
			modsub_path_obj = mock( "Mock 'modsub' path object" )
			@listpath.should_receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			modsub_path_obj.should_receive( :exist? ).twice.and_return( false )
            remote_path_obj = mock( "Mock 'remote' path object" )
			@listpath.should_receive( :+ ).with( 'remote' ).twice.and_return( remote_path_obj )
            remote_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			remote_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			remote_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end

		### Message moderation
		
		it "knows that subscription moderation is enabled if the dir/modpost file exists" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( true )
			
			@list.should be_moderated()
		end
		
		it "knows that subscription moderation is disabled if the dir/modpost file doesn't exist" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( false )

			@list.should_not be_moderated()
		end


		it "returns an empty array of message moderators for an open list" do
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).and_return( false )

			@list.message_moderators.should be_empty()
		end
	
	
		it "can return a list of message moderators' email addresses" do
			# Test the moderation config file for existence
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from the config file
			modpost_path_obj.should_receive( :read ).with( 1 ).and_return( nil )
			
			# Read subscribers from the default directory
			subscribers_dir = mock( "Mock moderator subscribers directory" )
			@listpath.should_receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			subscribers_dir.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end
		
		
		it "can return a list of message moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modpost_path_obj = mock( "Mock 'modpost' path object" )
			@listpath.should_receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			modpost_path_obj.should_receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			modpost_path_obj.should_receive( :read ).with( 1 ).and_return( '/' )
			modpost_path_obj.should_receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = mock( "Mock path object for customized moderator dir" )
			Pathname.should_receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			custom_mod_path.should_receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = Pathname.should_receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = mock( "Mock subscribers file for '#{email}'" )
				mock_subfile.should_receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			mods.should have(TEST_MODERATORS.length).members
			mods.should include( *TEST_MODERATORS )
		end


		### List owner
		
		it "returns nil when the list doesn't have an owner in its config" do
			@list.stub!( :config ).and_return({ '5' => nil })
			@list.owner.should == nil
		end
		
			
		it "can return the email address of the list owner" do
			@list.stub!( :config ).and_return({ '5' => TEST_OWNER })
			@list.owner.should == TEST_OWNER
		end

	end
	
	
	### 
	### Archive functions
	### 
	describe "archive functions" do
	
		before( :each ) do
			@listpath = TEST_LISTDIR.dup
			@list = Ezmlm::List.new( @listpath )
		end
		
		
		it "can return the count of archived posts" do
			numpath_obj = mock( "num file path object" )
			@listpath.should_receive( :+ ).with( 'num' ).and_return( numpath_obj )
			
			numpath_obj.should_receive( :exist? ).and_return( true )
			numpath_obj.should_receive( :read ).and_return( "1723:123123123" )
			
			@list.message_count.should == 1723
		end
	
		it "can return the count of archived posts to a list that hasn't been posted to" do
			numpath_obj = mock( "num file path object" )
			@listpath.should_receive( :+ ).with( 'num' ).and_return( numpath_obj )
			
			numpath_obj.should_receive( :exist? ).and_return( false )
			
			@list.message_count.should == 0
		end
		

		
		TEST_ARCHIVE_DIR = TEST_LISTDIR + 'archive'
		TEST_ARCHIVE_SUBDIRS = %w[ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 ]
		TEST_POST_FILES = %w[ 00 01 02 03 04 05 06 07 08 09 10 11 12 13 ]

		before( :each ) do
			@archive_dir = TEST_ARCHIVE_DIR.dup
			@archive_subdirs = TEST_ARCHIVE_SUBDIRS.dup
			@archive_subdir_paths = TEST_ARCHIVE_SUBDIRS.collect {|pn| TEST_ARCHIVE_DIR + pn }
			@archive_post_paths = TEST_POST_FILES.collect {|pn|
				TEST_ARCHIVE_DIR + TEST_ARCHIVE_SUBDIRS.last + pn
			  }
		end
		

		it "can return a TMail::Mail object parsed from the last archived post" do
			# need to find the last message
			archive_path_obj = mock( "archive path" )

			@listpath.should_receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			archive_path_obj.should_receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			archive_path_obj.should_receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			Pathname.should_receive( :glob ).with( :archive_dir_globpath ).
				and_return( @archive_subdir_paths )

			# Find the last numbered file under the last numbered directory we found
			# above.
			@archive_subdir_paths.last.should_receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_post_pathglob )
			Pathname.should_receive( :glob ).with( :archive_post_pathglob ).
				and_return( @archive_post_paths )

			TMail::Mail.should_receive( :load ).with( @archive_post_paths.last.to_s ).
				and_return( :mail_object )

			@list.last_post.should == :mail_object
		end
		
		
		it "returns nil for the last post if there is no archive directory for the list" do
			archive_path_obj = mock( "archive path" )

			@listpath.should_receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			archive_path_obj.should_receive( :exist? ).and_return( false )
			@list.last_post.should == nil
		end
		
		
		it "returns nil for the last post if there haven't been any posts to the list" do
			archive_path_obj = mock( "archive path" )
			mail_object = mock( "Mock TMail object" )

			@listpath.should_receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			archive_path_obj.should_receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			archive_path_obj.should_receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			Pathname.should_receive( :glob ).with( :archive_dir_globpath ).and_return( [] )

			@list.last_post.should == nil
		end
		
		
		it "raises a RuntimeError if the last archive directory doesn't have any messages in it" do
			archive_path_obj = mock( "archive path" )
			mail_object = mock( "Mock TMail object" )

			@listpath.should_receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			archive_path_obj.should_receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			archive_path_obj.should_receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			Pathname.should_receive( :glob ).with( :archive_dir_globpath ).
				and_return( @archive_subdir_paths )

			@archive_subdir_paths.last.should_receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_post_pathglob )
			Pathname.should_receive( :glob ).with( :archive_post_pathglob ).
				and_return( [] )

			lambda {
				@list.last_post
			}.should raise_error( RuntimeError, /unexpectedly empty/i )
		end
		
		
		it "can fetch the date of the last archived post" do
			mail_object = mock( "Mock TMail object" )

			@list.should_receive( :last_post ).and_return( mail_object )
			mail_object.should_receive( :date ).and_return( :the_message_date )

			@list.last_message_date.should == :the_message_date
		end

		
		it "can fetch the date of the last archived post" do
			mail_object = mock( "Mock TMail object" )

			@list.should_receive( :last_post ).and_return( mail_object )
			mail_object.should_receive( :date ).and_return( :the_message_date )

			@list.last_message_date.should == :the_message_date
		end

		
		it "can fetch the author of the last archived post" do
			mail_object = mock( "Mock TMail object" )

			@list.should_receive( :last_post ).and_return( mail_object )
			mail_object.should_receive( :from ).and_return( :the_message_author )

			@list.last_message_author.should == :the_message_author
		end

		
		it "can fetch the subject of the last archived post" do
			mail_object = mock( "Mock TMail object" )

			@list.should_receive( :last_post ).and_return( mail_object )
			mail_object.should_receive( :from ).and_return( :the_message_author )

			@list.last_message_author.should == :the_message_author
		end

	end


	it "can fetch the body of an archived post by message id"
	it "can fetch the header of an archived post by message id"
	
	it "can return a hash of the subjects of all archived posts to message ids" 
	it "can return an Array of the subjects of all archived posts"

	it "can return a hash of the threads of all archived posts to message ids"
	it "can return an Array of the threads of all archived posts"

	it "can return a hash of the authors of all archived posts to message ids"
	it "can return an Array of the authors of all archived posts"

end


