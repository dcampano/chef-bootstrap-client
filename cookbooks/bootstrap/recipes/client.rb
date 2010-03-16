#
# Cookbook Name:: bootstrap
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

root_group = value_for_platform(
  "openbsd" => { "default" => "wheel" },
  "freebsd" => { "default" => "wheel" },
  "default" => "root"
)

gem_package "chef" do
  version node[:bootstrap][:chef][:client_version]
end

case node[:bootstrap][:chef][:init_style]
when "runit"
  client_log = node[:bootstrap][:chef][:client_log]
  show_time  = "false"
  include_recipe "runit"
  runit_service "chef-client"
when "init"
  client_log = "\"#{node[:bootstrap][:chef][:client_log]}\""
  show_time  = "true"

  directory node[:bootstrap][:chef][:run_path] do
    action :create
    owner "root"
    group root_group
    mode "755"
  end

  service "chef-client" do
    action :nothing
  end

  case node[:bootstrap][:chef][:init_platform]
  when "redhat"
    template "/etc/init.d/chef-client" do
      source "redhat-chef-client.erb"
      mode "755"      
    end
    service "chef-client" do
      action [ :enable, :start ]
    end
  end

end

chef_dirs = [
  node[:bootstrap][:chef][:log_dir],
  node[:bootstrap][:chef][:path],
  "/etc/chef"
]

chef_dirs.each do |dir|
  directory dir do
    owner "root"
    group root_group
    mode "755"
  end
end

template "/etc/chef/client.rb" do
  source "client.rb.erb"
  owner "root"
  group root_group
  mode "644"
  variables(
    :client_log => client_log,
    :show_time  => show_time
  )
end
