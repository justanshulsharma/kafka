#
# Cookbook Name:: kafka
# Attributes:: default
#
default[:kafka][:scala_version] = "2.11"
default[:kafka][:version] = "0.8.2.2"
default[:kafka][:download_url] = "http://www.eu.apache.org/dist/kafka"
default[:kafka][:checksum] = "ee845b947b00d6d83f51a93e6ff748bb03e5945e4f3f12a77534f55ab90cb2a8"

default[:kafka][:install_dir] = "/opt/kafka"
default[:kafka][:data_dir] = "/var/kafka"
default[:kafka][:log_dir] = "/var/log/kafka"
default[:kafka][:chroot_suffix] = "brokers"

default[:kafka][:num_partitions] = 2
default[:kafka][:broker_id] = node['ipaddress'].rpartition('.').last
default[:kafka][:broker_host_name] = node['ipaddress']
default[:kafka][:port] = 9092
default[:kafka][:threads] = nil
default[:kafka][:log_flush_interval] = 10000
default[:kafka][:log_flush_time_interval] = 1000
default[:kafka][:log_flush_scheduler_time_interval] = 1000
default[:kafka][:log_retention_hours] = 168
default[:kafka][:zk_connectiontimeout] = 1000000

default[:kafka][:user] = "kafka"
default[:kafka][:group] = "kafka"

default[:kafka][:log4j_logging_level] = "INFO"
default[:kafka][:jmx_port] = 9999
