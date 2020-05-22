# # encoding: utf-8

# Inspec test for recipe sample_spring_boot_app::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

describe user('hab') do
  it { should exist }
end

describe file('/bin/hab') do
  it { should exist }
  it { should be_symlink }
end

# This needs to be updated each time Habitat is released so we ensure we're getting the version
# required by this cookbook.
describe command('hab -V') do
  its('stdout') { should match(%r{^hab 0.83.0/}) }
  its('exit_status') { should eq 0 }
end

describe directory('/hab/pkgs/%APP_HAB_PKG%') do
  it { should exist }
end

describe command('/bin/hab sup -h') do
  its(:stdout) { should match(/The Habitat Supervisor/) }
end

describe systemd_service('hab-sup.service') do
   it { should be_installed }
   it { should be_enabled }
   it { should be_running }
 end
