require! {
  os
  \child_process
  \./Storage
  \./Block
}


class Miner

  @CPUS = os.cpus!length

  (@address) ->

  start: ->
    @workers = []
    rates = []
    inter = setInterval ->
      console.log (fold (+), 0, rates), 'h/s'
    , 1000

    for let i from 0 til Miner.CPUS
      @workers.push worker = child_process.fork "./Worker"
      worker.on \message (msg) ~>
        if msg.found?
          console.log 'Found block !', msg.found
          map (.kill!), @workers
          clearInterval inter
          codecoin.broadcast msg.block

        if msg.rate?
          rates[i] = msg.rate

      worker.send do
        start: (Number.MAX_SAFE_INTEGER / Miner.CPUS) * i
        stop: ((Number.MAX_SAFE_INTEGER / Miner.CPUS) * (i + 1)) - 1
        target: 1
        address: @address
        lastHash: last codecoin.storage.headers


    # else
    #   console.log 'Client'
    #   process.on \message (msg) ->
    #     process.send 'LOL'
      # newBlock = new Block last codecoin.storage.headers
      # newBlock.prependCoinBase @address
      # hash = newBlock.mine!
      # console.log hash

module.exports = Miner
