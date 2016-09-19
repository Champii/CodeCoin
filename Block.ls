class Serializable

  serialize: ->
    res = {}

    @
      |> keys
      |> filter ~> not isType \Function @[it]
      # |> map ~>
      #   if @series
      #     @[it].serialize!
      #   else
      #     @[it]
      |> each   ~> res[it] = @[it]

    # console.log 'RES' res
    Pack.encode res

  @deserialize = ->
    new @ Pack.decode it



class TxTree extends Serializable

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

  (@previousHash, @target = Buffer.from('00000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', \hex), @timestamp = new Date, @nonce = 0) ->

class Block extends Serializable

  (@previousHash, @txList = [], @hash) ->
    @header = new BlockHeader @previousHash
    @header.txCount = @txList.length

  prependCoinBase: ->
    @txList.unshift new CoinBaseTx it

  mine: ->
    if not @hash?
      @hash = @header.mine!

  verify: ->
    ### verify
    # txlist (nb, tree)
    # previousHash
    # currentHash

  @getFromDht = (hash) ->
    console.log 'SEARCHING' hash
    codecoin.dht.FindValue hash, (err, value) ->
      console.log 'FOUND' value
      console.log err, value


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
