#!/usr/bin/env rake
# vim: set nosta noet ts=4 sw=4:

require 'pathname'

begin
	require 'rake/extensiontask'
rescue LoadError
	abort "This Rakefile requires rake-compiler (gem install rake-compiler)"
end

PROJECT = 'ezmlm'
BASEDIR = Pathname.new( __FILE__ ).expand_path.dirname.relative_path_from( Pathname.getwd )
LIBDIR  = BASEDIR + 'lib'

if Rake.application.options.trace
    $trace = true
    $stderr.puts '$trace is enabled'
end

# parse the current library version
$version = ( LIBDIR + "#{PROJECT}.rb" ).read.split(/\n/).
	select{|line| line =~ /VERSION =/}.first.match(/([\d|.]+)/)[1]

task :default => [ :spec, :docs, :package ]


########################################################################
### P A C K A G I N G
########################################################################

require 'rubygems'
require 'rubygems/package_task'
spec = Gem::Specification.new do |s|
	s.email        = 'mahlon@martini.nu'
	s.homepage     = 'https://bitbucket.org/mahlon/Ruby-Ezmlm'
	s.authors      = [
		'Mahlon E. Smith <mahlon@martini.nu>',
		'Michael Granger <ged@faeriemud.org>',
		'Jeremiah Jordan <jeremiah.m.jordan@gmail.com>'
	]
	s.platform     = Gem::Platform::RUBY
	s.summary      = "Interact with Ezmlm-IDX mailing lists."
	s.name         = PROJECT
	s.version      = $version
	s.license      = 'BSD-3-Clause'
	s.has_rdoc     = true
	s.require_path = 'lib'
	s.bindir       = 'bin'
	s.files        = File.read( __FILE__ ).split( /^__END__/, 2 ).last.split
	# s.executables  = %w[]
	s.description  = <<-EOF
This is a ruby interface for interacting with ezmlm-idx, an email list
manager for use with the Qmail MTA, and the messages contained therein.
(The -idx provides an extended feature set over the original ezmlm
environment.)
	EOF
	s.extensions = FileList[ "ext/**/extconf.rb" ]
	s.required_ruby_version = '>= 2.1'

	s.add_dependency 'mail', "~> 2.6"
	s.add_development_dependency 'rake-compiler', "~> 1.0"
end

Gem::PackageTask.new( spec ) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end

# Build the C extension for hashing addresses.
Rake::ExtensionTask.new( 'ezmlm/hash', spec )


########################################################################
### D O C U M E N T A T I O N
########################################################################

begin
	require 'rdoc/task'

	desc 'Generate rdoc documentation'
	RDoc::Task.new do |rdoc|
		rdoc.name       = :docs
		rdoc.rdoc_dir   = 'docs'
		rdoc.main       = "README.rdoc"
		# rdoc.options    = [ '-f', 'fivefish' ]
		rdoc.rdoc_files = [ 'lib', *FileList['ext/*/*.c'], *FileList['*.rdoc'] ]
	end

	RDoc::Task.new do |rdoc|
		rdoc.name       = :doc_coverage
		rdoc.options    = [ '-C1' ]
	end

rescue LoadError
	$stderr.puts "Omitting 'docs' tasks, rdoc doesn't seem to be installed."
end


########################################################################
### T E S T I N G
########################################################################

begin
    require 'rspec/core/rake_task'
    task :test => :spec

    desc "Run specs"
    RSpec::Core::RakeTask.new do |t|
        t.pattern = "spec/**/*_spec.rb"
    end

    desc "Build a coverage report"
    task :coverage do
        ENV[ 'COVERAGE' ] = "yep"
        Rake::Task[ :spec ].invoke
    end

rescue LoadError
    $stderr.puts "Omitting testing tasks, rspec doesn't seem to be installed."
end



########################################################################
### M A N I F E S T
########################################################################
__END__
ext/ezmlm/hash/hash.c
ext/ezmlm/hash/hash.h
ext/ezmlm/hash/extconf.rb
lib/ezmlm/list.rb
lib/ezmlm/list/message.rb
lib/ezmlm/list/thread.rb
lib/ezmlm/list/author.rb
lib/ezmlm.rb

