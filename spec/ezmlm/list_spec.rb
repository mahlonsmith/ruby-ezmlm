#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent
	libdir = basedir + "lib"
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require_relative '../spec_helpers'
require 'ezmlm'

describe Ezmlm::List do

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
			allow(@list).to receive( :config ).and_return({ 'L' => :the_list_name })
			expect(@list.name).to eq(:the_list_name)
		end


		it "can return the configured list host" do
			allow(@list).to receive( :config ).and_return({ 'H' => :the_list_host })
			expect(@list.host).to eq(:the_list_host)
		end


		it "can return the configured list address" do
			allow(@list).to receive( :config ).and_return({ 'L' => TEST_LIST_NAME, 'H' => TEST_LIST_HOST })
			expect(@list.address).to eq("%s@%s" % [ TEST_LIST_NAME, TEST_LIST_HOST ])
		end


		CONFIG_KEYS = %w[ F X D T L H C 0 3 4 5 6 7 8 9 ]

		it "can fetch the list config as a Hash" do
			config_path = double( "Mock config path" )
			expect(@listpath).to receive( :+ ).with( 'config' ).and_return( config_path )
			expect(config_path).to receive( :exist? ).and_return( true )
			expect(config_path).to receive( :read ).and_return( TEST_CONFIG )

			expect(@list.config).to be_an_instance_of( Hash )
			expect(@list.config.size).to eq(CONFIG_KEYS.length)
			expect(@list.config.keys).to include( *CONFIG_KEYS )
		end


		it "raises an error if the list config file doesn't exist" do
			config_path = double( "Mock config path" )
			expect(@listpath).to receive( :+ ).with( 'config' ).and_return( config_path )
			expect(config_path).to receive( :exist? ).and_return( false )

			expect {
				@list.config
			}.to raise_error( RuntimeError, /does not exist/ )
		end


		it "can return a list of subscribers' email addresses" do
			subscribers_dir = TEST_LISTDIR + 'subscribers'

			expectation = expect(Pathname).to receive( :glob ).with( subscribers_dir + '*' )

			TEST_SUBSCRIBERS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			subscribers = @list.subscribers

			expect(subscribers.size).to eq(TEST_SUBSCRIBERS.length)
			expect(subscribers).to include( *TEST_SUBSCRIBERS )
		end


		### Subscriber moderation

		it "knows that subscription moderation is enabled if the dir/modsub file exists" do
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).and_return( true )

			expect(@list).to be_closed()
		end

		it "knows that subscription moderation is enabled if the dir/remote file exists" do
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).and_return( false )

			remote_path_obj = double( "Mock 'remote' path object" )
			expect(@listpath).to receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			expect(remote_path_obj).to receive( :exist? ).and_return( true )

			expect(@list).to be_closed()
		end


		it "knows that subscription moderation is disabled if neither the dir/modsub nor " +
		   "dir/remote files exist" do
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).and_return( false )

			remote_path_obj = double( "Mock 'remote' path object" )
			expect(@listpath).to receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			expect(remote_path_obj).to receive( :exist? ).and_return( false )

			expect(@list).not_to be_closed()
		end


		it "returns an empty array of subscription moderators for an open list" do
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).and_return( false )

			remote_path_obj = double( "Mock 'remote' path object" )
			expect(@listpath).to receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			expect(remote_path_obj).to receive( :exist? ).and_return( false )

			expect(@list.subscription_moderators).to be_empty()
		end

		it "can return a list of subscription moderators' email addresses" do
			# Test the moderation config files for existence
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).twice.and_return( true )
			remote_path_obj = double( "Mock 'remote' path object" )
			expect(@listpath).to receive( :+ ).with( 'remote' ).and_return( remote_path_obj )
			expect(remote_path_obj).to receive( :exist? ).once.and_return( true )

			# Try to read directory names from both config files
			expect(modsub_path_obj).to receive( :read ).with( 1 ).and_return( nil )
			expect(remote_path_obj).to receive( :read ).with( 1 ).and_return( nil )

			# Read subscribers from the default directory
			subscribers_dir = double( "Mock moderator subscribers directory" )
			expect(@listpath).to receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			expect(subscribers_dir).to receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = expect(Pathname).to receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			expect(mods.size).to eq(TEST_MODERATORS.length)
			expect(mods).to include( *TEST_MODERATORS )
		end


		it "can return a list of subscription moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).twice.and_return( true )
			expect(@listpath).to receive( :+ ).with( 'remote' )

			# Try to read directory names from both config files
			expect(modsub_path_obj).to receive( :read ).with( 1 ).and_return( '/' )
			expect(modsub_path_obj).to receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = double( "Mock path object for customized moderator dir" )
			expect(Pathname).to receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			expect(custom_mod_path).to receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = expect(Pathname).to receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			expect(mods.size).to eq(TEST_MODERATORS.length)
			expect(mods).to include( *TEST_MODERATORS )
		end

		it "can get a list of modererators when remote subscription moderation is enabled" +
           " and the modsub configuration is empty" do
			# Test the moderation config files for existence
			modsub_path_obj = double( "Mock 'modsub' path object" )
			expect(@listpath).to receive( :+ ).with( 'modsub' ).twice.and_return( modsub_path_obj )
			expect(modsub_path_obj).to receive( :exist? ).twice.and_return( false )
            remote_path_obj = double( "Mock 'remote' path object" )
			expect(@listpath).to receive( :+ ).with( 'remote' ).twice.and_return( remote_path_obj )
            expect(remote_path_obj).to receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			expect(remote_path_obj).to receive( :read ).with( 1 ).and_return( '/' )
			expect(remote_path_obj).to receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = double( "Mock path object for customized moderator dir" )
			expect(Pathname).to receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			expect(custom_mod_path).to receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = expect(Pathname).to receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.subscription_moderators
			expect(mods.size).to eq(TEST_MODERATORS.length)
			expect(mods).to include( *TEST_MODERATORS )
		end

		### Message moderation

		it "knows that subscription moderation is enabled if the dir/modpost file exists" do
			modpost_path_obj = double( "Mock 'modpost' path object" )
			expect(@listpath).to receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			expect(modpost_path_obj).to receive( :exist? ).and_return( true )

			expect(@list).to be_moderated()
		end

		it "knows that subscription moderation is disabled if the dir/modpost file doesn't exist" do
			modpost_path_obj = double( "Mock 'modpost' path object" )
			expect(@listpath).to receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			expect(modpost_path_obj).to receive( :exist? ).and_return( false )

			expect(@list).not_to be_moderated()
		end


		it "returns an empty array of message moderators for an open list" do
			modpost_path_obj = double( "Mock 'modpost' path object" )
			expect(@listpath).to receive( :+ ).with( 'modpost' ).and_return( modpost_path_obj )
			expect(modpost_path_obj).to receive( :exist? ).and_return( false )

			expect(@list.message_moderators).to be_empty()
		end


		it "can return a list of message moderators' email addresses" do
			# Test the moderation config file for existence
			modpost_path_obj = double( "Mock 'modpost' path object" )
			expect(@listpath).to receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			expect(modpost_path_obj).to receive( :exist? ).twice.and_return( true )

			# Try to read directory names from the config file
			expect(modpost_path_obj).to receive( :read ).with( 1 ).and_return( nil )

			# Read subscribers from the default directory
			subscribers_dir = double( "Mock moderator subscribers directory" )
			expect(@listpath).to receive( :+ ).with( 'mod/subscribers' ).and_return( subscribers_dir )
			expect(subscribers_dir).to receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = expect(Pathname).to receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			expect(mods.size).to eq(TEST_MODERATORS.length)
			expect(mods).to include( *TEST_MODERATORS )
		end


		it "can return a list of message moderators' email addresses when the moderators " +
		   "directory has been customized" do
			# Test the moderation config files for existence
			modpost_path_obj = double( "Mock 'modpost' path object" )
			expect(@listpath).to receive( :+ ).with( 'modpost' ).twice.and_return( modpost_path_obj )
			expect(modpost_path_obj).to receive( :exist? ).twice.and_return( true )

			# Try to read directory names from both config files
			expect(modpost_path_obj).to receive( :read ).with( 1 ).and_return( '/' )
			expect(modpost_path_obj).to receive( :read ).with().and_return( TEST_CUSTOM_MODERATORS_DIR )

			custom_mod_path = double( "Mock path object for customized moderator dir" )
			expect(Pathname).to receive( :new ).with( TEST_CUSTOM_MODERATORS_DIR ).and_return( custom_mod_path )

			# Read subscribers from the default file
			expect(custom_mod_path).to receive( :+ ).with( '*' ).and_return( :mod_sub_dir )
			expectation = expect(Pathname).to receive( :glob ).with( :mod_sub_dir )

			TEST_MODERATORS.each do |email|
				mock_subfile = double( "Mock subscribers file for '#{email}'" )
				expect(mock_subfile).to receive( :read ).and_return( "T#{email}\0" )

				expectation.and_yield( mock_subfile )
			end

			mods = @list.message_moderators
			expect(mods.size).to eq(TEST_MODERATORS.length)
			expect(mods).to include( *TEST_MODERATORS )
		end


		### List owner

		it "returns nil when the list doesn't have an owner in its config" do
			allow(@list).to receive( :config ).and_return({ '5' => nil })
			expect(@list.owner).to eq(nil)
		end


		it "can return the email address of the list owner" do
			allow(@list).to receive( :config ).and_return({ '5' => TEST_OWNER })
			expect(@list.owner).to eq(TEST_OWNER)
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
			numpath_obj = double( "num file path object" )
			expect(@listpath).to receive( :+ ).with( 'num' ).and_return( numpath_obj )

			expect(numpath_obj).to receive( :exist? ).and_return( true )
			expect(numpath_obj).to receive( :read ).and_return( "1723:123123123" )

			expect(@list.message_count).to eq(1723)
		end

		it "can return the count of archived posts to a list that hasn't been posted to" do
			numpath_obj = double( "num file path object" )
			expect(@listpath).to receive( :+ ).with( 'num' ).and_return( numpath_obj )

			expect(numpath_obj).to receive( :exist? ).and_return( false )

			expect(@list.message_count).to eq(0)
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
			archive_path_obj = double( "archive path" )

			expect(@listpath).to receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			expect(archive_path_obj).to receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			expect(archive_path_obj).to receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			expect(Pathname).to receive( :glob ).with( :archive_dir_globpath ).
				and_return( @archive_subdir_paths )

			# Find the last numbered file under the last numbered directory we found
			# above.
			expect(@archive_subdir_paths.last).to receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_post_pathglob )
			expect(Pathname).to receive( :glob ).with( :archive_post_pathglob ).
				and_return( @archive_post_paths )

			expect(TMail::Mail).to receive( :load ).with( @archive_post_paths.last.to_s ).
				and_return( :mail_object )

			expect(@list.last_post).to eq(:mail_object)
		end


		it "returns nil for the last post if there is no archive directory for the list" do
			archive_path_obj = double( "archive path" )

			expect(@listpath).to receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			expect(archive_path_obj).to receive( :exist? ).and_return( false )
			expect(@list.last_post).to eq(nil)
		end


		it "returns nil for the last post if there haven't been any posts to the list" do
			archive_path_obj = double( "archive path" )
			mail_object = double( "Mock TMail object" )

			expect(@listpath).to receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			expect(archive_path_obj).to receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			expect(archive_path_obj).to receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			expect(Pathname).to receive( :glob ).with( :archive_dir_globpath ).and_return( [] )

			expect(@list.last_post).to eq(nil)
		end


		it "raises a RuntimeError if the last archive directory doesn't have any messages in it" do
			archive_path_obj = double( "archive path" )
			mail_object = double( "Mock TMail object" )

			expect(@listpath).to receive( :+ ).with( 'archive' ).and_return( archive_path_obj )
			expect(archive_path_obj).to receive( :exist? ).and_return( true )

			# Find the last numbered directory under the archive dir
			expect(archive_path_obj).to receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_dir_globpath )
			expect(Pathname).to receive( :glob ).with( :archive_dir_globpath ).
				and_return( @archive_subdir_paths )

			expect(@archive_subdir_paths.last).to receive( :+ ).with( '[0-9]*' ).
				and_return( :archive_post_pathglob )
			expect(Pathname).to receive( :glob ).with( :archive_post_pathglob ).
				and_return( [] )

			expect {
				@list.last_post
			}.to raise_error( RuntimeError, /unexpectedly empty/i )
		end


		it "can fetch the date of the last archived post" do
			mail_object = double( "Mock TMail object" )

			expect(@list).to receive( :last_post ).and_return( mail_object )
			expect(mail_object).to receive( :date ).and_return( :the_message_date )

			expect(@list.last_message_date).to eq(:the_message_date)
		end


		it "can fetch the date of the last archived post" do
			mail_object = double( "Mock TMail object" )

			expect(@list).to receive( :last_post ).and_return( mail_object )
			expect(mail_object).to receive( :date ).and_return( :the_message_date )

			expect(@list.last_message_date).to eq(:the_message_date)
		end


		it "can fetch the author of the last archived post" do
			mail_object = double( "Mock TMail object" )

			expect(@list).to receive( :last_post ).and_return( mail_object )
			expect(mail_object).to receive( :from ).and_return( :the_message_author )

			expect(@list.last_message_author).to eq(:the_message_author)
		end


		it "can fetch the subject of the last archived post" do
			mail_object = double( "Mock TMail object" )

			expect(@list).to receive( :last_post ).and_return( mail_object )
			expect(mail_object).to receive( :from ).and_return( :the_message_author )

			expect(@list.last_message_author).to eq(:the_message_author)
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


