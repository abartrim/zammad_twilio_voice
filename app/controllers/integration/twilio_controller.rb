require 'builder'

class Integration::TwilioController < ApplicationController
  skip_before_action :verify_csrf_token
  before_action :check_configured, :check_token

  @@event_endpoint_url = nil
  
  #TODO: Replace this with a user update or cache so it will scale and be managed
  @@in_call = {}
  
  def status
    # puts "status called"
    call
    # local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)
    # cti = Cti::Driver::Twilio.new(params: local_params, config: config_integration)
    # result = cti.process
    # return send_default
  end
  
  def events
    # puts "events called"
    call
    # Our outbound call to the agent call event
    # { 
      #   "Direction" = > "outbound-dial",
      #   "CallbackSource" = > "call-progress-events",
      #   "CallStatus" = > "completed",
      #   "To" = > "+14805555555",
      #   "Called" = > "+14805555555",
      #   "ForwardedFrom" = > "+16105508445",
      #   "CallSid" = > "CA4c3a40051b5903bfb5aa775075b34aae",
      #   "ParentCallSid" = > "CA4bcb45f4529892689fdff0db33df454b",
      #   "CalledVia" = > "+16105508445",
      #   "From" = > "+16105508445",
      # }
      # local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)
    # cti = Cti::Driver::Twilio.new(params: local_params, config: config_integration)
    # result = cti.process
    # return send_default
  end

  def call
    # puts "call method called"
    # Should this be in an init function? Used for Dial/Number Callback
    if @@event_endpoint_url == nil
        api_path      = Rails.configuration.api_path
        http_type     = Setting.get('http_type')
        fqdn          = Setting.get('fqdn')
        twilio_token  = Setting.get('twilio_token')
        endpoint = "#{http_type}://#{fqdn}#{api_path}/twilio/#{twilio_token}/events"
        @@event_endpoint_url = endpoint
    end

    local_params = ActiveSupport::HashWithIndifferentAccess.new(params.permit!.to_h)

    cti = Cti::Driver::Twilio.new(params: local_params, config: config_integration)

    result = {}
    begin
      result = cti.process
    rescue => err
      puts "Error processing cti: #{err.class} with msg: #{err.message}"
      raise err
    end

    if local_params['_ignore']
      # Just return empty response
      return send_default
    end

    # check if inbound call should get rejected
    if result[:action] == 'reject'
      response_reject(result,false)
      return true
    end

    # check if outbound call changes the outbound caller_id
    # if result[:action] == 'set_caller_id'
    #   response_set_caller_id(result)
    #   return true
    # end

    if result[:action] == 'invalid_direction'
      response_error('Invalid direction!')
      return true
    end

    # Need to get a list of available agents
    if local_params['event'] == 'newCall'
      begin
        agent_numbers = get_agents(cti, local_params['from'])
        if agent_numbers.length > 0
          response_dial(
            agent_numbers, 
            local_params['from'], 
            @@event_endpoint_url
          )
        else
          # Reject with message
          response_reject(nil, true)
        end
      rescue => err
        puts "Error: #{err}"
        response_reject(nil,true)
      end
      return true
    # elsif local_params['_hangup'] == 'response'
    #   response_reject(nil, false)
    #   return true
    elsif local_params['event'] == 'answer'
      # Set agent on phone
      update_agent_on_phone(local_params['Called'], true)
      return send_default
    elsif local_params['event'] == 'hangup'
      # Set agent off phone
      update_agent_on_phone(local_params['answeringNumber'], false)
      return send_default
    else
      # puts "returning default response"
      return send_default
    end
    true
  end

  private

  def send_default
      send_data(Twilio::TwiML::VoiceResponse.new.to_s, type: 'application/xml; charset=UTF-8;')
      return true
  end

  # Return a list of available agent numbers for the system to call
  # Check who is online, has their phone scwitch toggled on,
  # not ooo and not currently already on a call
  def get_agents(cti, from)
    agent_numbers = []
    session_ids = Sessions.sessions
    # loop through sessions and see if phone is on
    for sid in session_ids do
      sess = Sessions.get(sid)
      userid = sess[:user]['id']
      next unless userid.present?
      user = User.find(userid)
      # Is Agent? and NOT OOO and is NOT on a call AND has cti=true (slide on)
      # on_call = user.preferences['cti_call']
      on_call = @@in_call[user.phone]
      # puts "On call: user:#{user.phone} no_call:#{on_call}"
      if user.role?('Agent') && !user.out_of_office? && user.preferences['cti'] && !on_call
        if user.phone.present?
          agent_numbers << user.phone
        end
      end
    end
    agent_numbers
  end

  def update_agent_on_phone(agent, state)
    return if !agent.present?
    return if state == nil
    agent = agent.tr('+','')
    session_ids = Sessions.sessions
    for sid in session_ids do
      sess = Sessions.get(sid)
      userid = sess[:user]['id']
      next unless userid.present?
      user = User.find(userid)
      if user.role?('Agent') && user.phone.present? && user.phone == agent
        # puts "update_agent_on_phone for agent=#{agent} with state=#{state}"
        @@in_call[agent] = state
        # user.preferences['cti_call'] = state
        # puts "Checking user prefs for cti_call: #{user.preferences['cti_call']}"
      end
    end
  end

  def check_token
    if Setting.get('twilio_token') != params[:token]
      response_unauthorized('Invalid token, please contact your admin!')
      return
    end

    true
  end

  def check_configured
    http_log_config facility: 'twilio'

    if !Setting.get('twilio_integration')
      response_error('Feature is disable, please contact your admin to enable it!')
      return
    end
    if config_integration.blank? || config_integration[:inbound].blank? || config_integration[:outbound].blank?
      response_error('Feature not configured, please contact your admin!')
      return
    end

    true
  end

  def xml_error(error, code)
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.instruct!
    content = xml.Response() do
      xml.Error(error)
    end
    send_data content, type: 'application/xml; charset=UTF-8;', status: code
  end

  def config_integration
    @config_integration ||= Setting.get('twilio_config')
  end

  def response_error(error)
    xml_error(error, 422)
  end

  def response_unauthorized(error)
    xml_error(error, 401)
  end

  def response_reject(result,msg)
    # TODO: Call came in and could not be answered by an agent, make a ticket
    resXML = Twilio::TwiML::VoiceResponse.new
    # This should be a record voice with transcribe and callback URL which should make a ticket with the audio file and transcription
    # resXML.say(
    #   voice: 'women', 
    #   language: 'en-AU', 
    #   message: 'No Agents available at the moment, please leave a message after the tone and someone will get back to you shortly'
    # )
    # resXML.record(timeout: 10, transcribe: true)
    
    # TODO: replace this with configured entry
    resXML.say(
      voice: 'women', 
      language: 'en-AU', 
      message: 'No Agents available at the moment, please try again later. Goodbye'
    ) if msg
    resXML.hangup
    send_data resXML.to_s, type: 'application/xml; charset=UTF-8;'
  end

  # def response_set_caller_id(result)
  #   # xml = Builder::XmlMarkup.new(indent: 2)
  #   # xml.instruct!
  #   # content = xml.Response() do
  #   #   xml.Dial(callerId: result[:params][:from_caller_id]) { xml.Number(result[:params][:to_caller_id]) }
  #   # end
  #   send_data(content, type: 'application/xml; charset=UTF-8;')
  # end

  def response_dial(result, from, url)
    resXML = Twilio::TwiML::VoiceResponse.new
    # resXML.say(
    #   voice: 'women', 
    #   language: 'en-AU', 
    #   message: 'Thanks for calling I.T. Shield, we are locating a security ninja for you, please be patient. Ninjas are tough to find at the best of times.'
    # )
    # resXML.play(
    #   loop: 1,
    #   url: 'https://cdn2.melodyloops.com/mp3/preview-action-mission.mp3'
    # )
    resXML.dial({
      hangup_on_star: true,
      caller_id: '16105508445'
    }) { |dial|
      for n in result do
        if n != from
          dial.number(n, {
            status_callback: url,
            status_callback_method: 'POST',
            status_callback_event: 'answered completed',
          })
        end
      end
    }
    res = resXML.to_s
    send_data res, type: 'application/xml; charset=UTF-8;'
  end
end
