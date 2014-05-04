module Agents
  class AddArtistAgent < Agent
    cannot_be_scheduled!
    cannot_receive_events!

    description <<-MD
      Use this Agent to create events for add artist flow
    MD

    event_description "User determined"

    def default_options
      { "keys" => {
        "beatport_url" => "beatport_url",
        "beatport_name" => "beatport_name",
        "soundcloud_username" => "soundcloud_username",
        "soundcloud_name" => "soundcloud_name"
        } 
      }
    end

    def handle_details_post(params)
      payload = {}
      if (params['artist_name'].length > 0 && (params['beatport_x'] == "on" || params['soundcloud_x'] == "on" || params['boilerroom_x'] == "on")) || 
         (params['beatport'].length > 0 && params['beatport_x'] == "on") ||
         (params['soundcloud'].length > 0 && params['soundcloud_x'] == "on")

        if params['beatport_x'] == "on"
          if params['beatport'].length > 0
            payload[options['keys']['beatport_url']] = params['beatport']
          else
            payload[options['keys']['beatport_name']] = params['artist_name']
          end
        end

        if params['soundcloud_x'] == "on"
          if params['soundcloud'].length > 0
            payload[options['keys']['soundcloud_username']] = params['soundcloud']
          else
            payload[options['keys']['soundcloud_name']] = params['artist_name']
          end
        end
        
        if params['boilerroom_x']
          # modify boilerroom filter agent
        end

        if payload.length > 0
          create_event(:payload => payload)
        end
        { :success => true }
      else
        { :success => false, :error => "You must tick an entry and provide appropriate values." }
      end
    end

    def working?
      true
    end

    def validate_options
    end
  end
end