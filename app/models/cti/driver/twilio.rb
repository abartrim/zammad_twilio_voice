class Cti::Driver::Twilio < Cti::Driver::Base

  def config
    conf = Setting.get('twilio_config')
  end

  def mapping(params)
    params['callId'] = params['CallSid']
    params['to'] = params['To'].tr('+','')
    params['from'] = params['From'].tr('+','')
    params['user'] = params['CallerName']
    # TODO: Get this from config...
    # New Call
    if params['Direction'] == 'inbound' && params['CallStatus']=='ringing'
      # puts "New customer call"

      # {
      #   AccountSid: 'ACc3b59f8ad2f84707b2d7ccc1683e5959',
      #   ApiVersion: '2010-04-01',
      #   CallSid: 'CA7c382bcc7f9cce2af04d2b86deef154c',
      #   CallStatus: 'ringing',
      #   Called: '+16105505555',
      #   CalledCity: 'NEWTOWN SQUARE',
      #   CalledCountry: 'US',
      #   CalledState: 'PA',
      #   CalledZip: '19085',
      #   Caller: '+14803335555',
      #   CallerCity: 'PHOENIX',
      #   CallerCountry: 'US',
      #   CallerName: '',
      #   CallerState: 'AZ',
      #   CallerZip: '85012',
      #   Direction: 'inbound',
      #   From: '+14803335555',
      #   FromCity: 'PHOENIX',
      #   FromCountry: 'US',
      #   FromState: 'AZ',
      #   FromZip: '85012',
      #   To: '+16105505555',
      #   ToCity: 'NEWTOWN SQUARE',
      #   ToCountry: 'US',
      #   ToState: 'PA',
      #   ToZip: '19085'
      # }
      params['direction'] = 'in'
      params['event'] = 'newCall'
    elsif params['Direction'] == 'outbound-dial' && 
      params['CallStatus']=='in-progress' && 
      params['CallbackSource'] == 'call-progress-events'
      # puts "Agent answered"

      # Status update, Answered
      # {
      #   ApiVersion: '2010-04-01',
      #   Called: '+14803801234',
      #   ParentCallSid: 'CA7c382bcc7f9cce2af04d2b86deef154c',
      #   CallStatus: 'in-progress',
      #   From: '+16105505555',
      #   Direction: 'outbound-dial',
      #   Timestamp: 'Sat, 08 Aug 2020 03:25:40 +0000',
      #   AccountSid: 'ACc3b59f8ad2f84707b2d7ccc1683e5959',
      #   CallbackSource: 'call-progress-events',
      #   CalledVia: '+16105505555',
      #   Caller: '+16105505555',
      #   SequenceNumber: '0',
      #   CallSid: 'CA5c0ef8e69cfe5581ac7d1358d03752e9',
      #   To: '+14803801234',
      #   ForwardedFrom: '+16105505555'
      # }
      params['direction'] = 'in'
      params['event'] = 'answer'
      params['answeringNumber'] = params['Called'].tr('+','')
      params['callId'] = params['ParentCallSid']
      # params['to'] = params['CalledVia'].tr('+','')
      # params['to'] = nil
      # params['from'] = nil
      # body = `event=answer&callId=${sid}&user=${user}&from=${from}&to=${to}&direction=in&answeringNumber=${dest}`
    elsif params['Direction'] == 'inbound' && 
      params['CallStatus']=='completed' && 
      params['CallbackSource'] == 'call-progress-events'
      # puts "Customer hungup"
      # Hangup
      # {
      #   Called: '+16105505555',
      #   ToState: 'PA',
      #   CallerCountry: 'US',
      #   Direction: 'inbound',
      #   Timestamp: 'Sat, 08 Aug 2020 03:26:02 +0000',
      #   CallbackSource: 'call-progress-events',
      #   CallerState: 'AZ',
      #   ToZip: '19085',
      #   SequenceNumber: '0',
      #   To: '+16105505555',
      #   CallSid: 'CA7c382bcc7f9cce2af04d2b86deef154c',
      #   ToCountry: 'US',
      #   CallerName: '',
      #   CallerZip: '85012',
      #   CalledZip: '19085',
      #   ApiVersion: '2010-04-01',
      #   CallStatus: 'completed',
      #   CalledCity: 'NEWTOWN SQUARE',
      #   Duration: '1',
      #   From: '+14803335555',
      #   CallDuration: '35',
      #   AccountSid: 'ACc3b59f8ad2f84707b2d7ccc1683e5959',
      #   CalledCountry: 'US',
      #   CallerCity: 'PHOENIX',
      #   ToCity: 'NEWTOWN SQUARE',
      #   FromCountry: 'US',
      #   Caller: '+14803335555',
      #   FromCity: 'PHOENIX',
      #   CalledState: 'PA',
      #   FromZip: '85012',
      #   FromState: 'AZ'
      # }
      params['direction'] = 'in'
      params['event'] = 'hangup'
      params['cause'] = 'normalClearing'
      params['answeringNumber'] = params['to']
      params['_hangup'] = 'response'
      # body = `event=hangup&cause=normalClearing&callId=${sid}&from=${from}&to=${to}&direction=in&answeringNumber=${to}`
    elsif params['Direction'] == 'outbound-dial' && 
      params['CallbackSource'] == 'call-progress-events' && 
      params['CallStatus'] == 'completed'
      # puts "Agent completed/hungup"
      # Our agent call has completed
      # We should send a hangup response
      params['direction'] = 'in'
      params['event'] = 'hangup'
      params['cause'] = 'normalClearing'
      params['answeringNumber'] = params['to']
      params['callId'] = params['ParentCallSid']
      params['_hangup'] = 'response'
    elsif params['Direction'] == 'outbound-dial' && 
      params['CallbackSource'] == 'call-progress-events' && 
      params['CallStatus'] == 'no-answer'
      # puts "Agent did not answer"
      # Should we respond that the parent call tries another number?
      # If this call is in progress already, we just ignore
      params['_ignore'] = true
    else
      # puts "Call event could not be mapped: #{params}"
      # params[action:] = 'reject'
    end
    params
  end 

  # TODO: need to add agent/device map lookup
  def push_open_ticket_screen_recipient
    user = super
    # puts "push_open_ticket_screen_recipient: #{user}"
    user
  end
end
