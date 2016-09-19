require! {
  \events : EventEmitter
  \node-dht : Dht
  bluebird
  \./Storage
  \./Block
}

class CodeCoin extends EventEmitter

  (@argv) ->
    @argv.connect = @argv?.connect?.split ',' or []

    console.progress 'DHT'
    @dht = new Dht @argv.port || 12345, @argv.connect.0, @argv.connect.1
    if not @argv.connect.length
      console.out 'Bootstrap mode. '
      @onDhtBootstraped!
    else
      @dht.on \bootstraped @~onDhtBootstraped

  onDhtBootstraped: ->
      @dht.on \unknownMsg @~dispatch

      console.log @dht.hash.Value!

      @storage = new Storage

      @storage
        .prepare!
        .then ~>
          console.progress 'Sync'
          @sync!

  start: ->

  sync: ->
    # @storage.read
    bucket = @dht.routing.FindNode @dht.hash

    if not bucket.length
      return console.log 'No peers found.'

    @expectedSyncs = []

    for node in bucket
      if node.hash.value is @dht.hash.value or
         @argv.port is node.port and node.ip is 'localhost'
        continue
      else
        @expectedSyncs.push sender: node.hash, answered: false
        node._SendMessage do
          msg: \Sync
          value: @storage.headers.length
          (err, status) ->
            console.log err, status

  dispatch: ->
    it.sender.hash = new Hash Array.from it.sender.hash.value.data
    switch it.msg
      | \Sync => @syncReceived it
      | \HeaderHash => @headerHashReceived it
      | \NewBlock => @newBlockReceived it
      | \Transaction => console.log 'NEW TRANSACTION RECEIVED' it

  syncReceived: (msg) ->
    bucket = @dht.routing.FindNode msg.sender.hash

    node = find (-> not it.hash.value.compare msg.sender.hash.value), bucket
    node._SendMessage do
      msg: 'HeaderHash'
      value: @storage.headers[msg.value to]
      (err, status) ->
        console.log err, status

  headerHashReceived: (msg) ->
    node = find (-> not it.sender.value.compare msg.sender.hash.value), @expectedSyncs
    if not node? or node.answered
      return

    node.answered = true
    node.headers = msg.value

    if msg.value.length
      console.log that, 'let to sync.'
    else
      console.log 'synced.'
      return @emit 'ready'

    for hash in msg.value
      Block.getFromDht hash

  newBlockReceived: (msg) ->
    console.log 'NEW BLOCK RECEIVED' msg

  broadcast: (msg) ->
    @dht.FindNode @dht.hash, (err, value) ->
      console.log 'NODE' value
      console.log err, value

module.exports = CodeCoin
