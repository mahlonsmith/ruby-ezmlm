# 
# Packaging Rake Tasks
# 
# 

require 'rake/packagetask'
require 'rake/gempackagetask'

Rake::GemPackageTask.new( GEMSPEC ) do |task|
	task.gem_spec = GEMSPEC
	task.need_tar = false
	task.need_tar_gz = true
	task.need_tar_bz2 = true
	task.need_zip = true
end


### Task: install
task :install_gem => [:package] do
	$stderr.puts 
	installer = Gem::Installer.new( %{pkg/#{PKG_FILE_NAME}.gem} )
	installer.install
end

### Task: uninstall
task :uninstall_gem => [:clean] do
	uninstaller = Gem::Uninstaller.new( PKG_FILE_NAME )
	uninstaller.uninstall
end



