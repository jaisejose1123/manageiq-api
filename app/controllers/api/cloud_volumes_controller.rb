module Api
  class CloudVolumesController < BaseController
    include Subcollections::Tags

    def create_resource(_type, _id = nil, data = {})
      ext_management_system = ExtManagementSystem.find(data['ems_id'])

      klass = CloudVolume.class_by_ems(ext_management_system)

      validate = klass.validate_create_volume(ext_management_system)
      raise validate[:message] unless validate[:available]

      task_id = klass.create_volume_queue(session[:userid], ext_management_system, data)
      action_result(true, "Creating Cloud Volume #{data['name']} for Provider: #{ext_management_system.name}", :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def delete_resource(type, id, _data = {})
      delete_action_handler do
        cloud_volume = resource_search(id, type, collection_class(:cloud_volumes))
        task_id = cloud_volume.delete_volume_queue(User.current_user)
        action_result(true, "Deleting Cloud Volume #{cloud_volume.name}", :task_id => task_id)
      end
    end

    def options
      return super unless params[:ems_id]

      ems = ExtManagementSystem.find(params[:ems_id])

      raise BadRequestError, "No CloudVolume support for - #{klass}" unless defined?(ems.class::CloudVolume)

      klass = ems.class::CloudVolume

      raise BadRequestError, "No DDF specified for - #{klass}" unless klass.respond_to?(:params_for_create)

      render_options(:cloud_volumes, :form_schema => klass.params_for_create(ems))
    end
  end
end
