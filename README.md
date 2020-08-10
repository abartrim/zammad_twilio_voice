# Welcome to Twilio Voice extension for Zammad

Zammad is a web based open source helpdesk/customer support system with many
features to manage customer communication via several channels like telephone,
facebook, twitter, chat and e-mails. It is distributed under version 3 of the
GNU AFFERO General Public License (GNU AGPLv3).

This Add-on for Zammad extends the base Zammad CTI Integration/Package, adding Twilio Voice support

This Integration/Package provides a few call flows;

1. RING-ALL: [done]
    Motivation - Simple small user flow to ring all Agents numbers when in incoming call arrives
    
    Forward in-coming call to all logged in Agents at once.
    * Customer calls configured Twilio phone number
    * The system returns a list of available agents to Twilio that follow the following conditions
      Agent Logged In 
        AND Agent has toggled the Phone Notification switch to 'on'
        AND Agent is not already on a call
        AND Agent is not Out Of Office
        AND Agent is not the caller (Drops call when this occurs, you should not be able to call yourself)
    * First answered call will be connected and remaining calls will be canceled.
    This is a "very" simple flow and has potential issues
    * If the Agents number goes to voicemail the call will still be connected, disconnecting the other outgoing agent calls
    * busy signal does not impact flow
    If there are no available Agents, a provided message will be played to the caller and a hangup
    TODO: Support voicemail/recording/transcription in twilio with auto ticket generation containing, voice file and transcription

1. SIMPLE-QUEUE [under development]
    Motivation - Simple small user flow to address issues in the RING-ALL flow

    * Similar to the RING-ALL flow with the exception that the caller is connected to a Twilio queue
    * Twilio will then attempt to call the first available Agent in the list
    * If not answered, the next Agent will be called and so on...
    * When answered, a message is played asking for if the Agent is able to take the call
    * Timeouts are set in the Integration interface for trying next agent

1. EXECUTE-FROM-TWILIO-STUDIO [not started]
    Motivation - Call flow can be controlled from the Twilio Studio graphical interface. Could be used for very complex and large implementations

    * An API endpoint for retrieving available Agents for the HTTP Twilio Study component
    * Event update endpoints to keep the Study flow and Zammad CTI interface in sync.

** Outgoing calls are not yet implemented, hoping to get that done in the next release.

## Status

Initial commit, still under development and not fully functional.

## Installing & Getting Started

To add the Integration/Package to Zammad, ensure the version is 3.3.x and upload the 'twilio_voice.szpm' file.
See Zammad docs (https://docs.zammad.org) for adding the 'twilio_voice.szpm' file through the Settings->Packages interface.

## Screenshots

TODO

## REST API

This package accepts Twilio call and status events. Returning TwilioML (TwiML) to direct the call flow.
See Twilio documentation for details https://www.twilio.com/docs/voice/twiml



