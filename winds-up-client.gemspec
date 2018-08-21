Gem::Specification.new do |s|
	s.name        = 'winds-up-client'
  s.version     = '0.0.2'
  s.date        = '2018-08-19'
  s.summary     = 'client for winds-up.com'
  s.description = 'Allows to access winds-up.com on the CLI'
  s.add_runtime_dependency 'mechanize', '~> 2.7'
  s.add_runtime_dependency 'date', '~> 1'
  s.add_runtime_dependency 'json', '~> 2.1'
  s.add_runtime_dependency 'terminal-table', '~> 1.8'
  s.add_runtime_dependency 'trollop', '~> 2.1'
  s.authors     = ['Olivier Abdesselam']
  s.executables << 'winds-up-client'
  s.files       = ['lib/winds-up-client.rb']
  s.homepage    =
    'http://github.com/yazgoo/winds-up-client'
	s.license = 'MIT'
end
