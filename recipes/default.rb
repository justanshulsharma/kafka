#
# Cookbook Name:: kafka
# Description:: Base configuration for Kafka
# Recipe:: default

# == Recipes
include_recipe "java"
include_recipe "runit"

java_home   = node['java']['java_home']

user = node[:kafka][:user]
group = node[:kafka][:group]

if node[:kafka][:broker_id].nil? || node[:kafka][:broker_id].empty?
  node.set[:kafka][:broker_id] = node[:ipaddress].gsub(".","")
end

if node[:kafka][:broker_host_name].nil? || node[:kafka][:broker_host_name].empty?
  node.set[:kafka][:broker_host_name] = node[:fqdn]
end

log "Broker id: #{node[:kafka][:broker_id]}"
log "Broker name: #{node[:kafka][:broker_host_name]}"

group group do
end

user user do
  comment "Kafka user"
  gid "kafka"
  home "/home/kafka"
  shell "/bin/noshell"
  supports manage_home: false
end

install_dir = node[:kafka][:install_dir]

directory "#{install_dir}" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

directory "#{install_dir}/bin" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

directory "#{install_dir}/config" do
  owner "root"
  group "root"
  mode 00755
  recursive true
  action :create
end

directory node[:kafka][:log_dir] do
  owner   user
  group   group
  mode    00755
  recursive true
  action :create
end

directory node[:kafka][:data_dir] do
  owner   user
  group   group
  mode    00755
  recursive true
  action :create
end

dirname = "kafka_#{node[:kafka][:scala_version]}-#{node[:kafka][:version]}"
tarball = "kafka_#{node[:kafka][:scala_version]}-#{node[:kafka][:version]}.tgz"
download_file = "#{node[:kafka][:download_url]}/#{node[:kafka][:version]}/#{tarball}"

remote_file "#{Chef::Config[:file_cache_path]}/#{tarball}" do
  #source 'http://www.eu.apache.org/dist/kafka/0.8.1.1/kafka_2.10-0.8.1.1.tgz'
  source download_file
  mode 00644
  checksum node[:kafka][:checksum]
end

execute "tar" do
  user  "root"
  group "root"
  cwd install_dir
  command "tar zxvf #{Chef::Config[:file_cache_path]}/#{tarball}"
end

execute "cp" do
  user  "root"
  group "root"
  cwd install_dir
  command "cp -pr #{install_dir}/#{dirname}/libs lib"
end

template "#{install_dir}/bin/service-control" do
  source  "service-control.erb"
  owner "root"
  group "root"
  mode  00755
  variables({
              install_dir: install_dir,
              log_dir: node[:kafka][:log_dir],
              java_home: java_home,
              java_jmx_port: node[:kafka][:jmx_port],
              java_class: "kafka.Kafka",
              user: user
  })
end

zookeeper_pairs = Array.new
if not Chef::Config.solo
  search(:node, "role:zookeeper AND chef_environment:#{node.chef_environment}").each do |n|
    zookeeper_pairs << "#{n[:fqdn]}:#{n[:zookeeper][:client_port]}"
  end
end


%w[server.properties log4j.properties].each do |template_file|
  template "#{install_dir}/config/#{template_file}" do
    source  "#{template_file}.erb"
    owner user
    group group
    mode  00755
    variables({
                kafka: node[:kafka],
                zookeeper_pairs: zookeeper_pairs
    })
  end
end

execute "chmod" do
  command "find #{install_dir} -name bin -prune -o -type f -exec chmod 644 {} \\; && find #{install_dir} -type d -exec chmod 755 {} \\;"
  action :run
end

execute "chown" do
  command "chown -R root:root #{install_dir}"
  action :run
end

execute "chmod" do
  command "chmod -R 755 #{install_dir}/bin"
  action :run
end

runit_service "kafka" do
  options({
            log_dir: node[:kafka][:log_dir],
            install_dir: install_dir,
            java_home: java_home,
            user: user
  })
end

if node.attribute?("collectd")
  template "#{node[:collectd][:plugin_conf_dir]}/collectd_kafka-broker.conf" do
    source "collectd_kafka-broker.conf.erb"
    owner "root"
    group "root"
    mode 00644
    notifies :restart, resources(service: "collectd")
  end
end

service "kafka" do
  action :start
end
