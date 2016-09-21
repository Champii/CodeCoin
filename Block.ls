
class TxTree

  ->

  resolve: ->

class InTx

  (@prevBlockHash = 0, @prevTxcHash = 0) ->


class OutTx

  (@ownerHash, @value = 0) ->


class Transaction

  ->
    @in = []
    @out = []

class CoinBaseTx extends Transaction

  (@address) ->
    super!
    @out.push new OutTx @address, 100000000

class BlockHeader

  version: 1

  (@previousHash, @txCount, @target = '00000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', @timestamp = new Date, @nonce = 0) ->

class Block

  (@previousHash, @txList = [], @hash) ->
    @header = new BlockHeader @previousHash, @txList.length

  prependCoinBase: ->
    @txList.unshift new CoinBaseTx it
    @header.txCount++

  mine: ->
    if not @hash?
      @hash = @header.mine!

  verify: (previousHash) ->

    tests = [
      @header.txCount is @txList.length
      @header.previousHash is previousHash
      @hash <= @header.target
      @hash is Hash.Create JSON.stringify(@header) .Value!
      # Verify transaction funds availability and merkelRoot validity
    ]

    if not all (is true), tests
      return false

    return true

  @getFromDht = (hash, done) ->
    # console.log 'SEARCHING' hash
    codecoin.dht.FindValue hash, (err, bucket, value) ->
      # console.log err, value
      done err, value

  @deserialize = ->
    block = new Block it.previousHash, it.txList, it.hash
    block.header = it.header
    block


# firstTx = new Transaction
# firstTx.in.push new InTx
# firstTx.out.push new OutTx 'myHash'
# firstBlock = new Block [firstTx], Hash.Create '0'

# a = JSON.stringify firstBlock
# console.log 'serie', a
# console.log 'deserialized' JSON.parse a
# console.log 'hashed block', Hash.Create a
# console.log 'HASHED HEADER' firstBlock.header.mine!

module.exports = Block
