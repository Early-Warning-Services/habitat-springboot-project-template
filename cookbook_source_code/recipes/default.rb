#
# Cookbook:: %APP_CB_NAME%
# Recipe:: default
#
# Copyright:: All Rights Reserved

# Set up Habitat area

group 'hab' do
  action :create
end

user 'hab' do
  gid 'hab'
  action :create
end

directory '/hab/cert' do
  recursive true
end

execute '/hab/cert/ssl-certificate.crt' do
  command 'curl -k %HAB_SSL_CERT_URL%  -o /hab/cert/ssl-certificate.crt'
end

cookbook_file '/root/hab-util.sh' do
  source 'hab-util.sh'
  owner 'root'
  group 'root'
  mode '700'
  action :create
end

execute 'hab-install' do
  command 'sh /root/hab-util.sh -H'
  not_if { File.exist?('/bin/hab') }
end

systemd_unit 'hab-sup.service' do
  content(
    Unit: {
      Description: 'The Chef Habitat Supervisor managed by Chef Infra',
    },
    Service: {
      Environment: ['SSL_CERT_FILE=/hab/cert/ssl-certificate.crt', 'HAB_BLDR_URL=%HAB_BLDR_URL%'],
      ExecStart: "/bin/hab sup run --strategy #{node['%APP_CB_NAME%']['strategy']} --url %HAB_BLDR_URL%",
      Restart: 'always',
    },
    Install: {
      WantedBy: 'multi-user.target',
    }
  )
  action [:create, :enable]
end

service 'hab-sup' do
  start_command 'systemctl start hab-sup && sleep 180'
  action :start
end

execute 'hab svc load' do
  command "sh /root/hab-util.sh -V #{node['%APP_CB_NAME%']['channel']} #{node['%APP_CB_NAME%']['habpkg']} #{node['%APP_CB_NAME%']['strategy']} #{node['%APP_CB_NAME%']['topology']}"
end
