require 'chef/provider/lwrp_base'
require_relative 'helpers_rhel'

class Chef
  class Provider
    class HttpdService
      class Rhel
        class Systemd < Chef::Provider::HttpdService::Rhel
          use_inline_resources if defined?(use_inline_resources)

          include Httpd::Helpers::Rhel

          def whyrun_supported?
            true
          end

          action :start do
            httpd_module "#{new_resource.parsed_name} :create systemd" do
              module_name 'systemd'
              httpd_version new_resource.parsed_version
              instance new_resource.parsed_instance
              notifies :reload, "service[#{new_resource.parsed_name} :create #{apache_name}]"
              action :create
            end

            directory "#{new_resource.parsed_name} :create /run/#{apache_name}" do
              path "/run/#{apache_name}"
              owner 'root'
              group 'root'
              mode '0755'
              recursive true
              action :create
            end

            template "#{new_resource.parsed_name} :create /usr/lib/systemd/system/#{apache_name}.service" do
              path "/usr/lib/systemd/system/#{apache_name}.service"
              source 'systemd/httpd.service.erb'
              owner 'root'
              group 'root'
              mode '0644'
              cookbook 'httpd'
              variables(apache_name: apache_name)
              action :create
            end

            directory "#{new_resource.parsed_name} :create /usr/lib/systemd/system/#{apache_name}.service.d" do
              path "/usr/lib/systemd/system/#{apache_name}.service.d"
              owner 'root'
              group 'root'
              mode '0755'
              recursive true
              action :create
            end

            service "#{new_resource.parsed_name} :create #{apache_name}" do
              service_name apache_name
              supports restart: true, reload: true, status: true
              provider Chef::Provider::Service::Init::Systemd
              action [:start, :enable]
            end
          end

          action :stop do
            service "#{new_resource.parsed_name} :stop #{apache_name}" do
              service_name apache_name
              supports restart: true, reload: true, status: true
              provider Chef::Provider::Service::Init::Systemd
              action :stop
            end
          end

          action :restart do
            service "#{new_resource.parsed_name} :restart #{apache_name}" do
              service_name apache_name
              supports restart: true, reload: true, status: true
              provider Chef::Provider::Service::Init::Systemd
              action :restart
            end
          end

          action :reload do
            service "#{new_resource.parsed_name} :reload #{apache_name}" do
              service_name apache_name
              supports restart: true, reload: true, status: true
              provider Chef::Provider::Service::Init::Systemd
              action :reload
            end
          end

          def delete_stop_service
            service "#{new_resource.parsed_name} :delete #{apache_name}" do
              supports restart: true, reload: true, status: true
              provider Chef::Provider::Service::Init::Systemd
              action [:stop, :disable]
            end
          end
        end
      end
    end
  end
end
