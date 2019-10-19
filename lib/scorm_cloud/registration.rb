module ScormCloud
  class Registration < ScormCloud::BaseObject
    attr_accessor :id, :courseid, :app_id, :registration_id, :course_id,
      :course_title, :learner_id, :dispatch_id, :learner_first_name, :learner_last_name,
      :email, :create_date, :first_access_date, :last_access_date,
      :completed_date, :instances, :last_course_version_launched
=begin
{
    "id": "tcvmbscgolf",
    "instance": 0,
    "updated": "2015-11-04T20:32:37.000Z",
    "registrationCompletion": "UNKNOWN",
    "registrationSuccess": "PASSED",
    "score": {
        "scaled": 93,
        "additionalProperties": {}
    },
    "totalSecondsTracked": 0,
    "course": {
        "id": "tcvm",
        "version": 0,
        "title": "Tin Can Golf Example",
        "courseLearningStandard": "XAPI",
        "updated": "2015-11-04T15:32:19.000Z"
    },
    "learner": {
        "id": "ConsoleLearner",
        "firstName": "Console",
        "lastName": "Learner"
    },
    "globalObjectives": [],
    "additionalProperties": {}
}
=end

    def self.learner_id_to_email(learner_id)
      regex = /[^_]+_(.+)/
      if m = regex.match(learner_id)
        return m[1]
      else
        learner_id
      end
    end
    def self.from_response(response)
      r = Registration.new
      generated_learner_id = if response.dispatch_id.present?
        d = ::Dispatch.find_by_scorm_id(response.dispatch_id)
        "#{d.learning_system.name}_#{response.learner.id}"
      else
        response.learner.id
      end
      r.set_attributes({
        "id"=>response.id,
        "courseid"=>response.course.id,
        "app_id"=>"",
        "registration_id"=>response.id,
        "course_id"=>response.course.id,
        "dispatch_id"=>response.dispatch_id,
        "course_title"=>response.course.title,
        "learner_id"=>generated_learner_id,
        "learner_first_name"=>response.learner.first_name,
        "learner_last_name"=>response.learner.last_name,
        "email"=>learner_id_to_email(generated_learner_id),
        "create_date"=>response.created_date,
        "first_access_date"=>response.first_access_date,
        "last_access_date"=>response.last_access_date,
        "completed_date"=>response.completed_date,
        "instances"=>response.instance,
        "last_course_version_launched"=>response.course.version
      })
      r
    end
    def self.from_xml(element)
      r = Registration.new
      r.set_attributes(element.attributes)
      element.children.each do |element|
        r.set_attr(element.name, element.text)
      end
      r
    end
  end
end
