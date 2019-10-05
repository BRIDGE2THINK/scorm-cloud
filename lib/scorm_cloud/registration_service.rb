module ScormCloud
  class RegistrationService < BaseService
    not_implemented :get_registration_list_results,
      :get_launch_info, :reset_global_objectives,
      :test_registration_post_url

    def create_registration(course_id, reg_id, first_name, last_name, learner_id, options = {})
      begin
        learner_schema = RusticiSoftwareCloudV2::LearnerSchema.new
        learner_schema.first_name = first_name
        learner_schema.last_name = last_name
        learner_schema.id = learner_id

        registration_schema = RusticiSoftwareCloudV2::CreateRegistrationSchema.new
        registration_schema.course_id = course_id
        registration_schema.registration_id = reg_id
        registration_schema.learner = learner_schema
        api_instance.create_registration(ENV['RUSTICI_TENANT'],registration_schema,options)
      rescue RusticiSoftwareCloudV2::ApiError=>e
        raise RequestError.new(e, e.message)
      end
      return true
    end

    def delete_registration(reg_id)
      begin
        api_instance.delete_registration(ENV['RUSTICI_TENANT'],reg_id)
      rescue RusticiSoftwareCloudV2::ApiError=>e
        raise RequestError.new(e, e.message)
      end
      return true
    end

    def get_registration_list(options = {})
      opts = {
        course_id: options[:courseid], # String | Only registrations for the specified course id will be included.
        learner_id: options[:learnerid], # String | Only registrations for the specified learner id will be included.
        since: options[:after], # DateTime | Only items updated since the specified ISO 8601 TimeStamp (inclusive) are included. If a time zone is not specified, UTC time zone will be used.
        _until: options[:until] # DateTime | Only items updated before the specified ISO 8601 TimeStamp (inclusive) are included. If a time zone is not specified, UTC time zone will be used.
      }
      begin
        regs = []
        loop do
          results = api_instance.get_registrations(ENV['RUSTICI_TENANT'],opts)
          regs |= results.registrations
          opts[:more] = results.more
          puts regs.count
          puts results.more
          break unless results.more.present?
        end
        regs.map { |e| Registration.from_response(e) }
      rescue RusticiSoftwareCloudV2::ApiError=>e
        #if e.message.ends_with? "is invalid"
          return []
        #else
        #  raise RequestError.new(e, e.message)
        #end
      end
    end
    def get_registration_detail(regid)
      result = api_instance.get_registration_progress(ENV['RUSTICI_TENANT'],regid)
      return Registration.from_response(result)
    end

    def get_registration_result(reg_id, format = "course")
      raise "Illegal format argument: #{format}" unless ["course","activity","full"].include?(format)
      begin
        result = api_instance.get_registration_progress(ENV['RUSTICI_TENANT'],reg_id)
        reg_result = result.registration_completion.downcase
        #override to match old api return
        reg_result = "complete" if reg_result == "completed"
      rescue RusticiSoftwareCloudV2::ApiError=>e
        raise RequestError.new(e, e.message)
      end
      return {first_access_date:result.first_access_date,last_access_date:result.last_access_date,create_date:result.created_date,completed_date:result.completed_date,complete:reg_result, success:result.registration_success.downcase, totaltime:result.total_seconds_tracked, score:result.score.try(:scaled) }
    end

    def launch(reg_id, redirect_url, options = {})
      launch_link_request = RusticiSoftwareCloudV2::LaunchLinkRequestSchema.new
      launch_link_request.redirect_on_exit_url = redirect_url
      result = api_instance.build_registration_launch_link(ENV['RUSTICI_TENANT'],reg_id, launch_link_request)
      return "#{api_instance.api_client.config.scheme}://#{api_instance.api_client.config.host}/#{result.launch_link}"
    end

    def get_launch_history(reg_id)

      result = api_instance.get_registration_launch_history(ENV['RUSTICI_TENANT'],reg_id)
      result.launch_history.map { |e| Launch.from_response(e) }
    end

    def reset_registration(reg_id)
      api_instance.delete_registration_progress(ENV['RUSTICI_TENANT'],reg_id)
      return true
    end

    def update_learner_info(learner_id, first_name, last_name, options)
      raise "Not Implemented: update_learner_info"
      params = options.merge({
        :fname => first_name,
        :lname => last_name,
        :learnerid => learner_id
      })
      xml = connection.call("rustici.registration.updateLearnerInfo", params)
      !xml.elements["/rsp/success"].nil?
    end

    def exists(reg_id)
      begin
        api_instance.get_registration(ENV['RUSTICI_TENANT'],reg_id)
        return true
      rescue RusticiSoftwareCloudV2::ApiError => e
        return false
      end
    end

    private
    def api_instance
      @api_instance ||= RusticiSoftwareCloudV2::RegistrationApi.new
    end

  end
end
