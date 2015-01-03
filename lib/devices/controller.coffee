# Load modules
upnpControl = require('upnp-controlpoint').UpnpControlPoint
wemo = require './drivers/wemo'
EventEmitter = require('events').EventEmitter

# Device store
devices = {}
sync = new EventEmitter()

# Handle state change
handleState = (deviceId, data) ->
  if devices[deviceId]?
    device = devices[deviceId].control
    switch device.device.deviceType
      when wemo.wallSwitch.type
        if data.type is 'power'
          device.setState data.value

      when wemo.lightSwitch.type
        if data.type is 'power'
          device.setState data.value

# Handle device event
handleEvent = (deviceId, evnt) ->
  # TODO : Make it DRY
  if devices[deviceId]?
    switch devices[deviceId].control.device.deviceType
      when wemo.wallSwitch.type
        if evnt.type is 'onOff'
          devices[deviceId].states.power = Boolean parseInt evnt.value

          sync.emit 'event',
            id: deviceId
            type: 'power'
            value: Boolean parseInt evnt.value

      when wemo.lightSwitch.type
        if evnt.type is 'onOff'
          devices[deviceId].states.power = Boolean parseInt evnt.value

          sync.emit 'event',
            id: deviceId
            type: 'power'
            value: Boolean parseInt evnt.value
        
      when wemo.motionSensor.type
        if evnt.type is 'motion'
          if devices[deviceId].states.motion isnt Boolean parseInt evnt.value
            devices[deviceId].states.motion = Boolean parseInt evnt.value

            sync.emit 'event',
              id: deviceId
              type: 'motion'
              value: Boolean parseInt evnt.value
      

# Handle each device
handleDevice = (device) ->
  switch device.deviceType
    when wemo.wallSwitch.type
      newDevice = new wemo.wallSwitch device
      
      devices[device.uuid] =
        name: 'wemo:wallSwitch:1'
        control: newDevice
        states:
          power: false

      newDevice.on 'event', (evnt) ->
        handleEvent device.uuid, evnt

      sync.emit 'device', device.uuid

    when wemo.lightSwitch.type
      newDevice = new wemo.lightSwitch device
      
      devices[device.uuid] =
        name: 'wemo:lightSwitch:1'
        control: newDevice
        states:
          power: false

      newDevice.on 'event', (evnt) ->
        handleEvent device.uuid, evnt

      sync.emit 'device', device.uuid

    when wemo.motionSensor.type
      newDevice = new wemo.motionSensor device
      
      devices[device.uuid] =
        name: 'wemo:motion:1'
        control: newDevice
        states:
          motion: false

      newDevice.on 'event', (evnt) ->
        handleEvent device.uuid, evnt

      sync.emit 'device', device.uuid

# Start UPNP and search periodically
upnp = new upnpControl()
upnp.on 'device', handleDevice
upnp.on 'device-lost', (deviceId) ->
  delete devices[deviceId]
  sync.emit 'device', deviceId
upnp.search()

setInterval () ->
  upnp.search()
, 1000 * 60

# Expose device store
exports.devices = devices
exports.sync = sync
exports.handleState = handleState