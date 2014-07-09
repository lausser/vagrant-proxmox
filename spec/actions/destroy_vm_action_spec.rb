require 'spec_helper'
require 'actions/proxmox_action_shared'

module VagrantPlugins::Proxmox

	describe Action::DestroyVm do

		let(:environment) { Vagrant::Environment.new vagrantfile_name: 'dummy_box/Vagrantfile' }
		let(:connection) { Connection.new 'https://your.proxmox.server/api2/json' }
		let(:env) { {machine: environment.machine(environment.primary_machine_name, :proxmox),
								 ui: double('ui').as_null_object,
								 proxmox_connection: connection} }

		subject(:action) { described_class.new(-> (_) {}, environment) }

		describe '#call' do

			before do
				env[:machine].id = 'localhost/100'
				connection.stub :delete_vm => 'OK'
			end

			it_behaves_like 'a proxmox action call'

			it 'should call the delete_vm function of connection' do
				connection.should_receive(:delete_vm).with node: 'localhost', vm_id: '100'
				action.call env
			end

			it 'should print a message to the user interface' do
				env[:ui].should_receive(:info).with 'Destroying the virtual machine...'
				env[:ui].should_receive(:info).with 'Done!'
				action.call env
			end

			context 'when the proxmox server responds with an error to the destroy request' do

				context 'when the proxmox server replies with an internal server error to the destroy request' do
					it 'should raise a VMDestroyError' do
						connection.stub(:delete_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMDestroyError
					end
				end

				context 'when the proxmox server replies with an internal server error to the task status request' do
					it 'should raise a VMDestroyError' do
						connection.stub(:delete_vm).and_raise ApiError::ServerError
						expect { action.send :call, env }.to raise_error Errors::VMDestroyError
					end
				end

				context 'when the proxmox server does not reply the task status request with OK' do
					it 'should raise a VMDestroyError' do
						connection.stub :delete_vm => 'destroy vm error'
						expect { action.send :call, env }.to raise_error Errors::VMDestroyError, /destroy vm error/
					end
				end

			end

		end

	end
end
