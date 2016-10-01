require! {
  fs
  path
  bluebird
  # \./Hash
}

fs.mkdir = bluebird.promisify fs.mkdir
fs.readFile = bluebird.promisify fs.readFile
fs.writeFile = bluebird.promisify fs.writeFile
fs.readdir = bluebird.promisify fs.readdir
fs.appendFile = bluebird.promisify fs.appendFile
fs.access = bluebird.promisify fs.access

# console.log Hash

class Storage

  @PATH = '/home/fgreiner/.codecoin/'
  @WALLET_PATH = '/home/fgreiner/.codecoin/wallets/'
  @HEADERS_FILE = 'headers'
  @HEADERS_PATH = path.resolve @PATH, @HEADERS_FILE

  @firstBlockHash = Hash.Create '0'

  ->
    @headers = []
    @addresses = []

  prepare: ->
    console.progress 'Preparing storage'
    @checkAndcreateStorageArbo!
      .then @~loadheaders
      .then @~loadAddresses

  checkAndcreateStorageArbo: ->
    fs
      .mkdir Storage.PATH
      .catch ->
      .then -> fs.mkdir Storage.WALLET_PATH
      .catch ->
      .then ~>
        fs.access Storage.HEADERS_PATH
      .catch ->
        fs.writeFile Storage.HEADERS_PATH, Storage.firstBlockHash.value

  loadAddresses: ->
    console.progress 'Loading wallet'
    fs
      .readdir Storage.WALLET_PATH
      .then ~>
        bluebird.map it, (-> Address.deserialize it)
      .then ~>
        @addresses = it
        console.log 'Addresses:', @addresses.length

  loadheaders: ->
    fs.readFile Storage.HEADERS_PATH
      .then @~parse
      .catch console.error

  parse: (buff) ->
    # console.log 'file' it
    while buff.length
      @headers.push buff.slice 0 Hash.LENGTH / 8
      buff = buff.slice Hash.LENGTH / 8

    console.log 'Height: ' + @headers.length + '.'

  addHeader: ->
    @headers.push buff = Buffer.from it, \hex
    fs.appendFile Storage.HEADERS_PATH, buff


module.exports = Storage
Address = require \./Address
