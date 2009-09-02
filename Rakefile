desc "Run specs"
task :spec do
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new do |t|
    t.libs << 'lib'
    t.spec_opts = %w(--color --format=specdoc --loadby mtime --reverse)
    t.spec_files = FileList['spec/*_spec.rb']
  end
end
