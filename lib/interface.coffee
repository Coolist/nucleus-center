module.exports = (d, s) ->

  # Config
  config = require '../config.json'

  # Set passed variables / methods
  devices = d.devices
  sync = d.sync
  handleState = d.handleState
  socket = s.socket
  store = s.store

  sync.on 'event', (data) ->
    socket.emit 'center:device:updateState', data
    
  sync.on 'device', (id) ->
    DEVICESsend devices, store

    if not devices[id]?
      console.log 'Device removed: ', id

  socket.on 'auth:getAccess', (data) ->
    if data[0].success
      store.access_token = data[0].token
      store.account = data[0].account

      console.log 'Auth SUCCESS: Got Access Token'

      # Get 'request token'
      AUTHsendRequest store
    else
      # Require new credentials

      console.log 'Auth FAIL: Couldn\'t get Access Token', data

  socket.on 'auth:getRequest', (data) ->

    if data[0].success
      store.request_token = data[0].token
      store.token_expires = data[0].expires
      store.account = data[0].account

      DEVICESsend devices, store

      console.log 'Auth SUCCESS: Got Request Token'
    else
      # Re-ask for 'request token'

      console.log 'Auth FAIL: Couldn\'t get Request Token', data

      AUTHsendRequest store

  socket.on 'device:setState', (data) ->
    handleState data.id,
      type: data.type
      value: data.value

  AUTHsendRequest = (store) ->
    socket.emit 'auth:getRequest',
      token: store.access_token
      place: config.place
      type: 'center'

  DEVICESsend = (devices, store) ->
    send = []

    if store.request_token
      for key, val of devices
        send.push
          id: key
          local_name: val.control.device.friendlyName
          name: val.name
          states: val.states

      socket.emit 'center:devices',
        send