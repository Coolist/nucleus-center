# Load modules
util = require 'util'
eventEmitter = require('events').EventEmitter

# Set constants
SERVICE_TYPE_BasicEvent = 'urn:Belkin:service:basicevent:1'
SERVICE_TYPE_WiFiSetup = 'urn:Belkin:service:WiFiSetup:1'
SERVICE_TYPE_TimeSync = 'urn:Belkin:service:timesync:1'
SERVICE_TYPE_FirmwareUpdate = 'urn:Belkin:service:firmwareupdate:1'
SERVICE_TYPE_Rules = 'urn:Belkin:service:rules:1'
SERVICE_TYPE_MetaInfo = 'urn:Belkin:service:metainfo:1'
SERVICE_TYPE_RemoteAccess = 'urn:Belkin:service:remoteaccess:1'

ACTION_SetBinaryState = 'SetBinaryState'

# Devices
exports.wallSwitch = class WallSwitch
  @type = 'urn:Belkin:device:controllee:1'

  constructor: (@device) ->
    eventEmitter.call @
    
    @service = findService @device, SERVICE_TYPE_BasicEvent

    if @service
      @service.on 'stateChange', (value) =>
        if value.BinaryState?
          @emit 'event',
            type: 'onOff'
            value: value.BinaryState
        else if value.UserAction?
          @emit 'event',
            type: 'userAction'
            value: value.UserAction

      @service.subscribe (err, data) ->

  util.inherits @, eventEmitter

  setState: (value) ->
    @service.callAction ACTION_SetBinaryState,
      BinaryState: if value then 1 else 0
    , (err, buf) =>
      if err
        console.log 'Set state error: ' + err + ' - ' + buf
      else
        @emit 'BinaryState', if value then 1 else 0

exports.lightSwitch = class LightSwitch
  @type = 'urn:Belkin:device:lightswitch:1'

  constructor: (@device) ->
    eventEmitter.call @

    @service = findService @device, SERVICE_TYPE_BasicEvent

    if @service
      @service.on 'stateChange', (value) =>
        if value.BinaryState?
          @emit 'event',
            type: 'onOff'
            value: value.BinaryState
        else if value.UserAction?
          @emit 'event',
            type: 'userAction'
            value: value.UserAction

      @service.subscribe (err, data) ->

  util.inherits @, eventEmitter

  setState: (value) ->
    @service.callAction ACTION_SetBinaryState,
      BinaryState: if value then 1 else 0
    , (err, buf) =>
      if err
        console.log 'Set state error: ' + err + ' - ' + buf
      else
        @emit 'BinaryState', if value then 1 else 0

exports.motionSensor = class MotionSensor
  @type = 'urn:Belkin:device:sensor:1'

  constructor: (@device) ->
    eventEmitter.call @

    @service = findService @device, SERVICE_TYPE_BasicEvent

    if @service
      @service.on 'stateChange', (value) =>
        if value.BinaryState?
          @emit 'event',
            type: 'motion'
            value: value.BinaryState

      @service.subscribe (err, data) ->

  util.inherits @, eventEmitter

findService = (device, service) ->
  for name of device.services
    if device.services[name].serviceType is service
      return device.services[name]

  return false
