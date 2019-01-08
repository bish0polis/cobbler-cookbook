#
# Cookbook:: cobblerd
# Spec:: uwsgi
#
# Copyright:: 2017-2018, Phoenix Specialty Manufacturing Company, All Rights Reserved.

require 'spec_helper'

describe 'cobblerd::uwsgi' do
  let(:packages) do
    %w[uwsgi uwsgi-plugin-python2]
  end

  platforms.each do |platform, details|
    versions = details['versions']
    versions.each do |version|
      context "On #{platform} #{version}" do
        let(:chef_run) do
          runner = ChefSpec::SoloRunner.new(platform: platform, version: version)
          runner.node.override['environment'] = 'dev'
          runner.converge(described_recipe)
        end

        it 'should install the required packages' do
          packages.each do |pkg|
            expect(chef_run).to install_package(pkg)
          end
        end

        it 'create the uwsgi configuration files' do
          expect(chef_run).to create_directory('/etc/uwsgi')
          expect(chef_run).to create_template('/etc/uwsgi/cobbler_web.ini')
          expect(chef_run).to create_template('/etc/uwsgi/cobbler_svc.ini')

          %w[cobbler-web cobbler-svc].each do |svc|
            service = chef_run.systemd_unit("#{svc}.service")
            expect(service).to do_nothing
            expect(chef_run).to create_template("/lib/systemd/system/#{svc}.service")

            template = chef_run.template("/lib/systemd/system/#{svc}.service")
            expect(template).to notify("systemd_unit[#{svc}.service]").to(:reload_or_restart).delayed
          end
        end

        it 'should enable and start the uwsgi services' do
          expect(chef_run).to enable_service('uwsgi')
          expect(chef_run).to start_service('uwsgi')

          expect(chef_run).to enable_service('cobbler-web')
          expect(chef_run).to start_service('cobbler-web')

          expect(chef_run).to enable_service('cobbler-svc')
          expect(chef_run).to start_service('cobbler-svc')
        end
      end
    end
  end
end
