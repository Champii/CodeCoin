require! {
  os
  \child_process
  \./Storage
  \./Block
}


class Miner

  @CPUS = os.cpus!length

  (@address) ->
    @started = false
    @workers = []
    codecoin.on \NewBlock ~>
      @stop!
      @start!

  start: ->
    if @started
      return

    console.log 'Start'
    @started = true
    @workers = []
    rates = []
    @inter = setInterval ->
      res = fold (+), 0, rates
      console.log res, 'h/s' if res and not Number.isNaN res
    , 1000

    newBlock = new Block((last codecoin.storage.headers).toString \hex)
    newBlock.prependCoinBase @address

    found = false

    for let i from 0 til Miner.CPUS
      @workers.push worker = child_process.fork "./Worker"
      worker.stdout = process.stdout
      worker.stderr = process.stderr
      worker.on \error (msg) ~>
        console.log 'WORKER error: ', msg
      worker.on \message (msg) ~>
        if msg.block? and not found
          found = true
          console.log 'Found!', msg.block.hash
          codecoin.storage.addHeader msg.block.hash

          codecoin.dht.Store (Hash.Create msg.block.hash), JSON.stringify(msg.block), (err, stored) ~>
            if err?
              console.log 'Error store'
              @stop!
              @start!
              return console.error err

            codecoin.broadcast do
              msg: \NewBlock
              value: msg.block

            @stop!
            @start!

        if msg.rate?
          rates[i] = msg.rate

      worker.send do
        start: (Number.MAX_SAFE_INTEGER / Miner.CPUS) * i
        stop: ((Number.MAX_SAFE_INTEGER / Miner.CPUS) * (i + 1)) - 1
        block: newBlock


  stop: ->
    if not @started
      return

    console.log 'Stop'

    map (.kill!), @workers
    clearInterval @inter
    @started = false



    # else
    #   console.log 'Client'
    #   process.on \message (msg) ->
    #     process.send 'LOL'
      # newBlock = new Block last codecoin.storage.headers
      # newBlock.prependCoinBase @address
      # hash = newBlock.mine!
      # console.log hash

module.exports = Miner
