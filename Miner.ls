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

    @started = true
    @workers = []
    rates = []
    @inter = setInterval ->
      console.log (fold (+), 0, rates), 'h/s'
    , 1000

    newBlock = new Block((last codecoin.storage.headers).toString \hex)
    newBlock.prependCoinBase @address

    found = false

    for let i from 0 til Miner.CPUS
      @workers.push worker = child_process.fork "./Worker"
      worker.on \message (msg) ~>
        if msg.block? and not found
          found = true
          console.log 'Found!', msg.block.hash
          codecoin.storage.addHeader msg.block.hash

          codecoin.dht.Store (Hash.Create msg.block.hash), JSON.stringify(msg.block), ->
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
