class TwilioVoice < ActiveRecord::Migration[5.1]
  
  def self.up
    # puts "Twilio migration up called"
    # return if it's a new setup
    # return if !Setting.exists?(name: 'system_init_done')
    Setting.create_if_not_exists(
      title:       'Twilio integration',
      name:        'twilio_integration',
      area:        'Integration::Switch',
      description: 'Defines if Twilio (https://www.twilio.com) is enabled or not.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'twilio_integration',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:           1,
        trigger:        ['menu:render', 'cti:reload'],
        authentication: true,
        permission:     ['admin.integration'],
      },
      frontend:    true
    )
    twilio_config = Setting.find_by(name: 'twilio_config')
    if !twilio_config
      Setting.create!(
        title:       'Twilio config',
        name:        'twilio_config',
        area:        'Integration::Twilio',
        description: 'Defines the Twilio config.',
        options:     {},
        state:       { 'outbound' => { 'routing_table' => [], 'default_caller_id' => '' }, 'inbound' => { 'block_caller_ids' => [] } },
        preferences: {
          prio:       2,
          permission: ['admin.integration'],
          cache:      ['twilioGetVoipUsers'],
        },
        frontend:    false,
      )
    else
      twilio_config.preferences[:cache] = ['twilioGetVoipUsers']
      twilio_config.save!
    end
    Setting.create_if_not_exists(
      title:       'TWILIO Token',
      name:        'twilio_token',
      area:        'Integration::Twilio',
      description: 'Token for twilio.',
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'twilio_token',
            tag:     'input',
          },
        ],
      },
      state:       ENV['TWILIO_TOKEN'] || SecureRandom.urlsafe_base64(20),
      preferences: {
        permission: ['admin.integration'],
      },
      frontend:    false
    )
  end
  
  def self.down
    # puts "Twilio migration down called"
    begin
      Setting.delete(name: 'twilio_integration')
      Setting.delete(name: 'twilio_config')
      Setting.delete(name: 'twilio_token')
    rescue => err
      puts "Twilio down migration error: #{err}"
    end
  end

  def change
    puts "Running migration for Twilio voice - change"
  end
end
