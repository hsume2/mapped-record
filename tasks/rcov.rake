desc "Run coverage tests"
task :rcov do
  rbfiles = File.join('test', '**', 'test_*.rb')
  system("rcov --rails #{"-x/Library" if PLATFORM['darwin']} #{Dir.glob(rbfiles).join(' ')}")
  system("open coverage/index.html") if PLATFORM['darwin']
end

namespace :rcov do
  desc "Delete coverage data"
  task :clobber do
    FileUtils.rm_rf('coverage') if File.exist?('coverage')
  end
end
