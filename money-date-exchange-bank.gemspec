$LOAD_PATH << File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name = 'money-date-exchange-bank'
  s.version = '0.0.1'
  s.summary = 'A Money Bank with support for exchanging currency with a'\
    ' specified rate or a historical date.'

  s.files = Dir.glob('lib/**/*') + %w[README.md]

  s.require_path = 'lib'
  s.required_ruby_version = Gem::Requirement.new('>= 2.5.3')

  s.authors = ['Marcelo Guindon']
  s.email = ['marcelo@teepublic.com']

  s.add_dependency('money', '~> 6.13')
end
