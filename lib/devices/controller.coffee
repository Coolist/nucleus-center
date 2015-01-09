# Load modules
upnpControl = require('upnp-controlpoint').UpnpControlPoint
wemo = require './drivers/wemo'
hue = require './drivers/hue'
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

      when 'urn:schemas-upnp-org:device:Basic:1'
        switch device.device.modelName
          when hue.bridge.type
            if data.type is 'power'
              device.setPower devices[deviceId].id, data.value
            else if data.type is 'brightness'
              data.value = 0 if data.value < 0
              data.value = 100 if data.value > 100

              data.value = Math.round(data.value / 100 * 255)

              device.setBrightness devices[deviceId].id, data.value
            else if data.type is 'color_temperature'
              device.setColorTemperature devices[deviceId].id, data.value

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

      when 'urn:schemas-upnp-org:device:Basic:1'
        switch devices[deviceId].control.device.modelName
          when hue.bridge.type
            if evnt.type is 'onOff'
              if devices[deviceId].states.power isnt evnt.value
                devices[deviceId].states.power = evnt.value

                sync.emit 'event',
                  id: deviceId
                  type: 'power'
                  value: evnt.value

            else if evnt.type is 'brightness'
              if devices[deviceId].states.brightness isnt evnt.value
                devices[deviceId].states.brightness = evnt.value

                sync.emit 'event',
                  id: deviceId
                  type: 'brightness'
                  value: Math.round(evnt.value / 255 * 100)

            else if evnt.type is 'color'
              if devices[deviceId].states.brightness isnt evnt.value
                devices[deviceId].states.brightness = evnt.value

                sync.emit 'event',
                  id: deviceId
                  type: 'color'
                  value: evnt.value

            else if evnt.type is 'color_temperature'
              if devices[deviceId].states.brightness isnt evnt.value
                devices[deviceId].states.brightness = evnt.value

                sync.emit 'event',
                  id: deviceId
                  type: 'color_temperature'
                  value: evnt.value
      

# Handle each device
handleDevice = (device) ->
  switch device.deviceType
    when wemo.wallSwitch.type
      newDevice = new wemo.wallSwitch device
      
      devices[device.uuid] =
        name: 'wemo:wallSwitch:1'
        local_name: device.friendlyName
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
        local_name: device.friendlyName
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
        local_name: device.friendlyName
        control: newDevice
        states:
          motion: false

      newDevice.on 'event', (evnt) ->
        handleEvent device.uuid, evnt

      sync.emit 'device', device.uuid

    when 'urn:schemas-upnp-org:device:Basic:1'
      switch device.modelName
        when hue.bridge.type
          newDevice = new hue.bridge device

          getDevices = () ->
            newDevice.getDevices (hueDevices) ->
              for hueDeviceId, value of hueDevices
                devices[device.uuid + ':' + hueDeviceId] =
                  name: 'hue:light:1'
                  local_name: value.name
                  id: hueDeviceId
                  control: newDevice
                  states:
                    power: value.state.on
                    color:
                      hue: value.state.hue
                      sat: value.state.sat
                    brightness: Math.round(value.state.bri / 255 * 100)
                    color_temperature: value.state.ct

              do (device, hueDeviceId) ->
                setTimeout () ->
                  for d, v of devices
                    if d.indexOf(device.uuid) > -1
                      getDevices()
                      return true
                , 60000

              sync.emit 'device'

          getDevices()

          newDevice.on 'event', (evnt) ->
            handleEvent device.uuid + ':' + evnt.id, evnt

# Start UPNP and search periodically
upnp = new upnpControl()
upnp.on 'device', handleDevice
upnp.on 'device-lost', (deviceId) ->
  deleted = false
  for device, value of devices
    if device.indexOf(deviceId) > -1
      delete devices[device]
      deleted = true

  if deleted
   sync.emit 'device', deviceId
upnp.search()

setInterval () ->
  upnp.search()
, 1000 * 60

# Expose device store
exports.devices = devices
exports.sync = sync
exports.handleState = handleState