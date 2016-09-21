require! {
  # \./Storage
  livescript
  \node-dht : Dht
}

global.Hash = Dht.Hash

require! {
  \./Block.ls
}

class Worker

  ->
    @scope = {}
    process.on \message (msg) ~>
      @scope = msg

      h = @mine @scope.block.header, @scope.start, @scope.end

      @scope.block.hash = h.Value!
      process.send block: @scope.block

  mine: (header, startNonce = 0, maxNonce = Number.MAX_SAFE_INTEGER) ->
    h = Hash.Create JSON.stringify header

    start = +new Date
    header.nonce = startNonce

    lastNonce = startNonce
    lastDate = start

    while header.target < h.Value! or header.nonce >= maxNonce

      middate = +new Date

      if (middate - lastDate) > 1000
        lastDate = middate
        process.send rate: header.nonce - lastNonce
        lastNonce = header.nonce

      header.nonce++
      h = Hash.Create JSON.stringify header

    h

new Worker
