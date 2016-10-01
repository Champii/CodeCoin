require! {
  async
  events : EventEmitter
  bluebird
  \node-dht : Dht

  \./Block
  \./Storage
}

class CodeCoin extends EventEmitter

  (@argv) ->
    @receivedLog = []

    @argv.connect = @argv?.connect?.split ',' or []
    @expectedSyncs = []

    console.progress 'DHT'
    @dht = new Dht @argv.port || 12345, @argv.connect.0, @argv.connect.1
    if not @argv.connect.length
      console.out 'Bootstrap mode. '
      @onDhtBootstraped!
    else
      @dht.on \bootstraped @~onDhtBootstraped

  onDhtBootstraped: ->

    console.log @dht.hash.Value!

    @storage = new Storage

    @storage
      .prepare!
      .then ~>
        @dht.on \unknownMsg @~dispatch
      .then ~>
        if @argv.recheck
          console.progress 'Rechecking blockchain'
          @recheck!
      .then ~>

        console.progress 'Sync'
        @sync!



  recheck: ->
    new Promise (resolve, reject) ~>
      hashs = map Hash~Create, @storage.headers[1 to]

      async.mapSeries hashs, Block.getFromDht, (err, blocks) ~>
        return reject err if err?

        bad = false
        # if any (~= null), blocks
        #   console.log 'Cannot find a block... '
        #   return

        blocks
          |> filter (?length)
          |> map JSON.parse >> Block.deserialize
          |> each ~>
            return if bad
            if it.verify (last @storage.headers).toString \hex
              # @storage.addHeader it.hash
              1
            else
              bad := true
              console.log 'BAD BLOCKCHAIN !'

        return reject! if bad
        console.log 'OK'
        resolve!
        # @ready = true
        # @emit 'ready'


  sync: ->
    # @storage.read
    bucket = @dht.routing.FindNode @dht.hash

    if not bucket.length
      return console.log 'No peers found.'

    @expectedSyncs = []


    for node in bucket
      if node.hash.value is @dht.hash.value or
         (@argv.port is node.port and node.ip is 'localhost')
        continue
      else
        @expectedSyncs.push sender: node.hash, answered: false
        node._SendMessage do
          msg: \Sync
          value: @storage.headers.length
          (err, status) ->
            # console.log err, status

    @syncTimer = setTimeout ~>
      if not @expectedSyncs.length
        return

      if all (-> !it.headers?), @expectedSyncs
        return console.log 'Timeout: No answers'

      @finishSync!
    , 3000

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
      value: map (.toString \hex), @storage.headers[msg.value to]
      (err, status) ->
        console.log err, status

  headerHashReceived: (msg) ->
    node = find (-> not it.sender.value.compare msg.sender.hash.value), @expectedSyncs
    if not node? or node.answered
      return

    node.answered = true
    node.headers = msg.value

    msg.value = map (-> Hash.Create it), msg.value

    if all (.answered), @expectedSyncs
      # console.log 'FinishSync All ansered'
      @finishSync!

  finishSync: ->
    # console.log map (.headers), @expectedSyncs
    clearTimeout @syncTimer


    expectedSyncs = @expectedSyncs
    @expectedSyncs = []
    first = []

    res = expectedSyncs
      |> filter (.headers?)
      |> map (.headers)
      |> filter (.length)
      |> -> first := it.0 || []; it
      |> all (=== first)

    if res
      if first.length
        console.log first.length, 'left to sync.', first
        blocks = []
        first = first
          |> map Hash~Create

        async.mapSeries first, Block.getFromDht, (err, blocks) ~>
          return console.log err if err?


          bad = false
          if any (is null), blocks
            console.log 'Cannot find a block... '
            return

          blocks
            |> filter (?length)
            |> map JSON.parse >> Block.deserialize
            |> each ~>
              return if bad
              if it.verify (last @storage.headers).toString \hex
                @storage.addHeader it.hash
              else
                bad := true
                console.log 'BAD BLOCKCHAIN !'

          return if bad
          console.log 'Synced'
          @ready = true
          @emit 'ready'

      else
        console.log 'Synced'
        @ready = true
        @emit 'ready'
        # @dht.on \unknownMsg @~dispatch

    else
      console.log 'Cannot sync, chain differs'
      console.log map (.headers), @expectedSyncs


    # if msg.value.length
    #   console.log that, 'left to sync.'
    # else
    #   console.log 'synced.'
    #   return @emit 'ready'

    # for hash in msg.value
    #   Block.getFromDht hash

  newBlockReceived: (msg) ->
    msgHash = Hash.Create JSON.stringify(msg.value) .Value!
    if @receivedLog[msgHash]?
      return ;

    @receivedLog[msgHash] = msg


    block = Block.deserialize msg.value
    if block.verify (last codecoin.storage.headers).toString \hex
      @storage.addHeader block.hash
      @emit 'NewBlock' block

      console.log 'Block'
      if msg.rebroadcast
        @broadcast msg

    else
      console.log 'BAD BLOCK'

  broadcast: (msg) ->
    msgHash = Hash.Create JSON.stringify(msg.value) .Value!
    @receivedLog[msgHash] = msg
    msg.rebroadcast = true if not msg.rebroadcast?
    # msg.ttl = 100 if not msg.ttl?

    bucket = @dht.routing.FindNode @dht.hash
    for node in bucket
      node._SendMessage msg

module.exports = CodeCoin
