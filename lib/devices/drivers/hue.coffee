# Load Modules
util = require 'util'
eventEmitter = require('events').EventEmitter
Rest = require('node-rest-client').Client

rest = new Rest()

# Devices
exports.bridge = class Bridge
  @type = 'Philips hue bridge 2012'

  constructor: (@device) ->
    eventEmitter.call @

    @ip = @device.host

  util.inherits @, eventEmitter

  getDevices: (callback) ->
    checkAuth @ip, () =>
      rest.get baseUrl(@ip) + '/lights', (data) ->
        callback data

  setPower: (id, value) ->
    state = if value then true else false

    rest.put baseUrl(@ip) + "/lights/#{id}/state",
      data:
        on: state
    , (data) =>

      if data[0]? and data[0].success?
        @emit 'event',
          id: id
          type: 'onOff'
          value: state

  setBrightness: (id, value) ->
    brightness = Math.round value

    brightness = 0 if brightness < 0
    brightness = 100 if brightness > 255

    rest.put baseUrl(@ip) + "/lights/#{id}/state",
      data:
        bri: brightness
    , (data) =>

      if data[0]? and data[0].success?
        @emit 'event',
          id: id
          type: 'brightness'
          value: brightness

  setColor: (id, value) ->
    if not value.hue? or not value.sat?
      return false

    hue = Math.round value.hue
    hue = 0 if hue < 0
    hue = 65535 if hue > 65535

    sat = Math.round value.sat
    sat = 0 if sat < 0
    sat = 255 if sat > 255

    rest.put baseUrl(@ip) + "/lights/#{id}/state",
      data:
        hue: hue
        sat: sat
    , (data) =>

      if data[0]? and data[0].success?
        @emit 'event',
          id: id
          type: 'color'
          value:
            hue: hue
            sat: sat

  setColorTemperature: (id, value) ->
    ct = Math.round value
    ct = 153 if ct < 153
    ct = 500 if ct > 500

    rest.put baseUrl(@ip) + "/lights/#{id}/state",
      data:
        ct: ct
    , (data) =>
      if data[0]? and data[0].success?
        @emit 'event',
          id: id
          type: 'color_temperature'
          value: ct

baseUrl = (ip) ->
  return 'http://' + ip + '/api/nucleus-home'

checkAuth = (ip, callback) ->
  rest.get baseUrl(ip), (data) ->
    if data[0] and data[0].error?
      rest.post 'http://' + ip + '/api',
        data:
          username: 'nucleus-home'
          devicetype: 'Nucleus Center'
      , (data) ->
        if data[0]? and data[0].success?
          callback()
        else if data[0]? and data[0].error? and data[0].error.type is 101
          console.log 'Press the link button on the Philips Hue.  Retrying in 5 seconds...'

          setTimeout () ->
            console.log 'Retrying Philips Hue link...'
            checkAuth ip, callback
          , 5000
    else if data.lights?
      callback()
    else
      console.log 'Unkown Philips Hue Access Error: ', data