module Api
  class CloudNetworksController < BaseController
    include Subcollections::Tags

    def delete_resource(type, id, _data = {})
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id
      cloud_network = resource_search(id, type, collection_class(type))

      if 0 < cloud_network.total_vms
        raise BadRequestError, "This cloud network cannot be deleted as it is still in use."
      end

      task_id = cloud_network.delete_cloud_network_queue(User.current_user.userid)
      action_result(true, "Deleting #{cloud_network.name}", :task_id => task_id)
    end
  end
end
