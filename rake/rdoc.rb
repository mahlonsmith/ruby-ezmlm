# 
# RDoc Rake tasks
# $Id$
# 

require 'rake/rdoctask'

### Task: rdoc
Rake::RDocTask.new do |rdoc|
	rdoc.rdoc_dir = 'docs/api'
	rdoc.title    = "%s -- %s" % [ GEMSPEC.name, GEMSPEC.summary ]

	rdoc.options += [
		'-w', '4',
		'-SHN',
		'-i', BASEDIR.to_s,
		'-f', 'darkfish',
		'-m', 'README',
		'-W', 'http://opensource.laika.com/browser/ruby-ezmlm/trunk/'
	  ]
	
	rdoc.rdoc_files.include 'README'
	rdoc.rdoc_files.include LIB_FILES.collect {|f| f.relative_path_from(BASEDIR).to_s }
end

