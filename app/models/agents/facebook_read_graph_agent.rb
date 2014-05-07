module Agents
  class FacebookReadGraphAgent < Agent
    cannot_receive_events!

    default_schedule "every_12h"

    UNIQUENESS_LOOK_BACK = 200
    UNIQUENESS_FACTOR = 3

    description <<-MD
      The Facebook Read Graph Agent reads data from the Facebook Graph API.

      Set `expected_update_period_in_days` to the maximum amount of time that you'd expect to pass between Events being created by this Agent.
    MD

    event_description <<-MD
      Events are the raw JSON provided by the Facebook Graph API. Should look something like:

      {}
    MD

    def validate_options
      unless options['oauth_access_token'].present? &&
        options['action'].present? &&
        options['object'].present? &&
        options['expected_update_period_in_days'].present?
        errors.add(:base, "oauth_access_token and expected_update_period_in_days are required")
      end
    end

    def working?
      event_created_within?(options['expected_update_period_in_days']) && !recent_error_logs?
    end

    def default_options
      {
        'oauth_access_token' => "",
        'action' => "object",
        'object' => "me",
        'edge' => '',
        'expected_update_period_in_days' => "2"
      }
    end

    def check
      facebook = Koala::Facebook::API.new(options['oauth_access_token'])
      objects = []
      if options['action'] == 'object'
        objects << facebook.get_object(options['object'])
      else
        page = facebook.get_connections(options['object'], options['edge'])
        while page do
          page.each do |object|
            objects << object
          end
          page = page.next_page
        end
      end

      old_events = previous_payloads objects.length
      objects.each do |object|
        if store_payload!(old_events, object)
          log "Storing new result for '#{object['name']}'"
          create_event :payload => object
        end
      end

      save!
    end

    def store_payload!(old_events, result)
      result_json = result.to_json
      old_events.each do |old_event|
        if old_event.payload.to_json == result_json
          old_event.expires_at = new_event_expiration_date
          old_event.save!
          return false
        end
       end
      return true
    end

    def previous_payloads(num_events)
      if options['uniqueness_look_back'].present?
        look_back = options['uniqueness_look_back'].to_i
      else
        # Larger of UNIQUENESS_FACTOR * num_events and UNIQUENESS_LOOK_BACK
        look_back = UNIQUENESS_FACTOR * num_events
        if look_back < UNIQUENESS_LOOK_BACK
          look_back = UNIQUENESS_LOOK_BACK
        end
      end
      events.order("id desc").limit(look_back)
    end
  end
end
