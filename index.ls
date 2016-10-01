require! {
  path
  bluebird
  \node-dht : Dht
  \prelude-ls
  \commander : argv
}

global.Hash = Dht.Hash

global import prelude-ls

require! {
  \./CodeCoin
  \./Address
  \./Miner
  \./Storage
}

argv
  .version '0.0.1'
  .option  '-p, --port <value>'             'Change listening port (default = 12345)'
  .option  '-c, --connect <ip>,<port>'      'Connect to boostrap node'

  .option  '-v, --verbose'                  'Verbose mode'

  .option  '-m, --mine'                     'Activate CPU miner'
  .option  '    --cpus <nb>'                'Number of core to dedicate to mining'

  .option  '-l, --list'                     'List address'
  .option  '-n, --new <name>'               'New address'

  .option  '-b, --basedir <path>'           'Change the base directory. Default = "~/.codecoin"'
  .option  '-d, --debug <path>'             'Write logs to <path>'

  .option  '-r, --recheck'                  'Recheck blockchain integrity'

  .parse   process.argv


# console.log 'ARSG', argv

oldError = console.error

console.error = (...args) ->
  oldError.apply console, map (-> 'ERROR: ' + it), args

console.progress = (...args) ->
  return if not argv.verbose
  console.out ...args

  size = args.join '' .length

  [to 25 - size]
    |> map -> '.'
    |> join ''
    |> process.stdout~write

oldLog = console.log

console.log = (...args) ->
  if argv.verbose
    oldLog.apply console, args

console.out = (...args) ->
  if argv.verbose
    map process.stdout~write, args

# if argv.debug


if argv.cpus
  Miner.CPUS = argv.cpus

if argv.basedir
  Storage.PATH = path.resolve(argv.basedir, '') + '/'
  Storage.WALLET_PATH = path.resolve(Storage.PATH, 'wallets') + '/'
  Storage.HEADERS_PATH = path.resolve Storage.PATH, Storage.HEADERS_FILE

if argv.new
  console.log 'Creating new Wallet...'
  Address.create argv.new
    .then process~exit
else
  global.codecoin = new CodeCoin argv

  codecoin.on \ready, ->
    if argv.mine
      console.log 'Starting miner...'
      miner = new Miner codecoin.dht.hash
      miner.start!
