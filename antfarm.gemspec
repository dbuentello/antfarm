Gem::Specification.new do |s| 
  s.name              = %q{antfarm}
  s.version           = '0.5.0'
  s.authors           = ['Bryan T. Richardson','Michael Berg']
  s.email             = %q{scada@sandia.gov}
  s.date              = %q{2010-06-02}
  s.summary           = %q{Passive network mapping tool}
  s.description       = %q{Passive network mapping tool capable of parsing data files
                           generated by common network administration tools, network
                           equipment configuration files, etc. Designed for use when
                           assessing critical infrastructure control systems.}
  s.homepage          = %q{http://ccss-sandia.github.com/antfarm}
  s.files             = Dir['{bin,lib,man}/**/*','README.md'].to_a
  s.require_paths     = ['lib']
  s.executables      << 'antfarm'
  s.has_rdoc          = false

  s.add_dependency 'trollop'
  s.add_dependency 'antfarm-core'
end