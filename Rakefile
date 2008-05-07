#!rake -*- ruby -*-
#
# Ruby-Ezmlm rakefile
#
# Based on Ben Bleything's Rakefile for Linen (URL?)
#
# Copyright (c) 2007 LAIKA, Inc.
#
# Mistakes:
#  * Michael Granger <mgranger@laika.com>
#

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}


require 'rubygems'

require 'rake'
require 'tmpdir'
require 'pathname'

$dryrun = false

# Pathname constants
BASEDIR       = Pathname.new( __FILE__ ).expand_path.dirname.relative_path_from( Pathname.getwd )
BINDIR        = BASEDIR + 'bin'
LIBDIR        = BASEDIR + 'lib'
DOCSDIR       = BASEDIR + 'docs'
VARDIR        = BASEDIR + 'var'
WWWDIR        = VARDIR  + 'www'
MANUALDIR     = DOCSDIR + 'manual'
RDOCDIR       = DOCSDIR + 'rdoc'
STATICWWWDIR  = WWWDIR  + 'static'
PKGDIR        = BASEDIR + 'pkg'
ARTIFACTS_DIR = Pathname.new( ENV['CC_BUILD_ARTIFACTS'] || '' )
RAKE_TASKDIR  = BASEDIR + 'rake'

TEXT_FILES    = %w( Rakefile README LICENSE ).
	collect {|filename| BASEDIR + filename }

SPECDIR       = BASEDIR + 'spec'
SPEC_FILES    = Pathname.glob( SPECDIR + '**/*_spec.rb' ).
	delete_if {|item| item =~ /\.svn/ }
# Ideally, this should be automatically generated.
SPEC_EXCLUDES = 'spec,monkeypatches,/Library/Ruby,/var/lib,/usr/local/lib'

BIN_FILES     = Pathname.glob( BINDIR + '*').
	delete_if {|item| item =~ /\.svn/ }
LIB_FILES     = Pathname.glob( LIBDIR + '**/*.rb').
	delete_if {|item| item =~ /\.svn/ }

RELEASE_FILES = BIN_FILES + TEXT_FILES + LIB_FILES + SPEC_FILES

require RAKE_TASKDIR + 'helpers.rb'

### Package constants
PKG_NAME      = 'ruby-ezmlm'
PKG_VERSION_FROM = LIBDIR + 'ezmlm.rb'
PKG_VERSION   = find_pattern_in_file( /VERSION = '(\d+\.\d+\.\d+)'/, PKG_VERSION_FROM ).first
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

require RAKE_TASKDIR + 'svn.rb'
require RAKE_TASKDIR + 'verifytask.rb'

if Rake.application.options.trace
	$trace = true
	log "$trace is enabled"
end

if Rake.application.options.dryrun
	$dryrun = true
	log "$dryrun is enabled"
	Rake.application.options.dryrun = false
end

### Project Gemspec
GEMSPEC = Gem::Specification.new do |gem|
	pkg_build = get_svn_rev( BASEDIR ) || 0
	
	gem.name    	= PKG_NAME
	gem.version 	= "%s.%s" % [ PKG_VERSION, pkg_build ]

	gem.summary     = "A Ruby programmatic interface to ezmlm-idx"
	gem.description = "Ruby-Ezmlm is a Ruby programmatic interface to ezmlm-idx " +
		"mailing lists, message archives, and command-line tools."

	gem.authors  	= "Michael Granger, Jeremiah Jordan"
	gem.email  		= "opensource@laika.com"
	gem.homepage 	= "http://opensource.laika.com/wiki/ruby-ezmlm"

	gem.rubyforge_project = 'laika'

	gem.has_rdoc 	= true

	gem.files      	= RELEASE_FILES.
		collect {|f| f.relative_path_from(BASEDIR).to_s }
	gem.test_files 	= SPEC_FILES.
		collect {|f| f.relative_path_from(BASEDIR).to_s }

  	gem.add_dependency( 'tmail', '>= 1.2.3.1' )
end


# Load task plugins
Pathname.glob( RAKE_TASKDIR + '*.rb' ).each do |tasklib|
	trace "Loading task lib #{tasklib}"
	require tasklib
end


### Default task
task :default  => [:clean, :spec, 'coverage:verify', :package]


### Task: clean
desc "Clean pkg, coverage, and rdoc; remove .bak files"
task :clean => [ :clobber_rdoc, :clobber_package, :clobber_coverage ] do
	files = FileList['**/*.bak']
	files.clear_exclude
	File.rm( files ) unless files.empty?
	FileUtils.rm_rf( 'artifacts' )
end


### Cruisecontrol task
desc "Cruisecontrol build"
task :cruise => [:clean, :coverage, :package] do |task|
	raise "Artifacts dir not set." if ARTIFACTS_DIR.to_s.empty?
	artifact_dir = ARTIFACTS_DIR.cleanpath
	artifact_dir.mkpath
	
	$stderr.puts "Copying coverage stats..."
	FileUtils.cp_r( 'coverage', artifact_dir )
	
	$stderr.puts "Copying packages..."
	FileUtils.cp_r( FileList['pkg/*'].to_a, artifact_dir )
end

