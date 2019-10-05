module ScormCloud
  class DispatchService < BaseService
    not_implemented  :get_destination_info

    def create_destination(name)
      destination_id = SecureRandom.uuid
      dest_schema = RusticiSoftwareCloudV2::DestinationSchema.new(name: name)
      dest_id_schema = RusticiSoftwareCloudV2::DestinationIdSchema.new(id: destination_id,data: dest_schema)
      list = RusticiSoftwareCloudV2::DestinationListSchema.new(destinations: [dest_id_schema])
      api_instance.create_destinations(ENV['RUSTICI_TENANT'],list)
      return destination_id
    end

    def update_destination(destination_id, name)
      dest_schema = RusticiSoftwareCloudV2::DestinationSchema.new(name: name)
      api_instance.set_destination(ENV['RUSTICI_TENANT'],destination_id,dest_schema)
      return true
    end

    def get_dispatch_list(page=1, dispatch_args = {})
      response = api_instance.get_dispatches(ENV['RUSTICI_TENANT'],{})
      response.dispatches.map { |e| Dispatch.from_response(e) }
    end

    def get_dispatch_info(dispatch_id)
      response = api_instance.get_dispatch(ENV['RUSTICI_TENANT'], dispatch_id, {})
      dispatch = RusticiSoftwareCloudV2::DispatchIdSchema.new(id: dispatch_id,
                                 data: response)
      Dispatch.from_response(dispatch)
    end

    def get_destination_list(page=1)
      response = api_instance.get_destinations(ENV['RUSTICI_TENANT'],{})
      response.destinations.map { |e| Destination.from_response(e) }
    end

    def delete_destination(destination_id)
      begin
        response = api_instance.delete_destination(ENV['RUSTICI_TENANT'], destination_id, {})
      rescue RusticiSoftwareCloudV2::ApiError=>e
        raise RequestError.new(e, e.message)
      end
      return true
    end

    def create_dispatch(course_id, destination_id, dispatch_attrs = {})
      dispatch_id = SecureRandom.uuid
      dispatch = RusticiSoftwareCloudV2::CreateDispatchSchema.new(destinationId: destination_id,
        courseId: course_id,
        allowNewRegistrations: true,
        instanced: false,
        registrationCap: dispatch_attrs[:registrationcap]||0,
        expirationDate: dispatch_attrs[:expirationdate],
        enabled: true
      )
      d_id = RusticiSoftwareCloudV2::CreateDispatchIdSchema.new(id: dispatch_id,
                                 data: dispatch)
      d_list = RusticiSoftwareCloudV2::CreateDispatchListSchema.new(dispatches: [d_id])
      response = api_instance.create_dispatches(ENV['RUSTICI_TENANT'], d_list, {})
      return dispatch_id
    end

    def delete_dispatches(dispatch_id)

      response = api_instance.delete_dispatch(ENV['RUSTICI_TENANT'], dispatch_id, opts = {})
      return true
    end

    def download_dispatches(dispatch_attrs = {})
      if dispatch_attrs[:dispatchid].present?
        tempfile = api_instance.get_dispatch_zip(ENV['RUSTICI_TENANT'], dispatch_attrs[:dispatchid])
        str = tempfile.open.read
        tempfile.delete
        return str
      else
        ds = ::Dispatch
        if dispatch_attrs[:destinationid].present?
          ds = ds.by_destinationid(dispatch_attrs[:destinationid])
        end
        if dispatch_attrs[:tags].present?
          ds = ds.by_taglist(dispatch_attrs[:tags])
        end
        return create_dispatch_zip(ds)
      end
    end

    def update_dispatches(dispatch_attrs = {})
      ## warning... needs to be implemented on dispatch model!
      return true
    end

    def download_dispatches_by_destination(destination_id)
      tempfile = api_instance.get_destination_dispatch_zip(ENV['RUSTICI_TENANT'], destination_id)
      str = tempfile.open.read
      tempfile.delete
      return str
    end

    def download_dispatches_by_course(courseid)
      ds = ::Dispatch.where(dispatchable_type:"Course",dispatchable_id:(::Course.find_by_scorm_id!(courseid).id) )
      return create_dispatch_zip(ds)
    end

    private
      def create_dispatch_zip(dispatches)
        t = Tempfile.new(["dispatch-zip",".zip"])
        Zip::File.open(t.path, Zip::File::CREATE) do |zipfile|
          dispatches.each do |d|
            file = api_instance.get_dispatch_zip(ENV['RUSTICI_TENANT'], d.scorm_id)
            zipfile.add("#{d.dispatchable.title.downcase.gsub(" ","_")}_#{d.learning_system.scorm_id}_dispatch_#{d.scorm_id}.zip", file.path)
          end
        end
        str = open(t).read
        t.close
        t.delete
        return str
      end
      def api_instance
        @api_instance ||= RusticiSoftwareCloudV2::DispatchApi.new
      end
  end
end
