# Config
config = require './config.json'

# Load Socket.io client and connect to server
io = require 'socket.io-client'
socket = io.connect config.server

# Storage for data
store = {}

console.log 'Socket IO client init...'

socket.on 'connect', () ->
  console.log 'Socket.io connected to Nucleus server.'

  socket.emit 'auth:getAccess',
    email: config.email
    password: config.password

###
socket.on 'event', (data) ->
  console.log 'Event: ', data
###

socket.on 'disconnect', () ->
  console.log 'Socket.io disconnected from Nucleus server.'

socket.on 'connect_error', (error) ->
  console.log 'Connection error: ', error

exports.socket = socket
exports.store = store