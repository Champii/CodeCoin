require! {
  fs
  path
  crypto
  eccrypto
  bluebird
}

# privateKey = crypto.randomBytes 32
# publicKey = eccrypto.getPublic privateKey
#
# str = "message to sign"
# msg = crypto
#         .createHash \sha256
#         .update str
#         .digest!
#
# eccrypto
#   .sign privateKey, msg
#   .then (sig) ->
#     console.log("Signature in DER format:", sig);
#     eccrypto.verify publicKey, msg, sig
#   .then ->
#       console.log("Signature is OK");
#   .catch ->
#     console.log("Signature is BAD");

fs.mkdir = bluebird.promisify fs.mkdir
fs.readFile = bluebird.promisify fs.readFile
fs.writeFile = bluebird.promisify fs.writeFile
fs.readdir = bluebird.promisify fs.readdir

class Address

  (@name) ->
    @folderPath = path.resolve Storage.WALLET_PATH, @name
    @privPath = path.resolve @folderPath, 'private.key'
    @pubPath = path.resolve @folderPath, 'public.key'

  load: ->
    fs
      .readFile @privPath
      .then ~> @privateKey = it
      .then ~> fs.readFile @pubPath
      .then ~> @publicKey = it

  @create = (name) ->
    folderPath = path.resolve Storage.WALLET_PATH, name
    privPath = path.resolve folderPath, 'private.key'
    pubPath = path.resolve folderPath, 'public.key'

    privateKey = crypto.randomBytes 32
    publicKey = eccrypto.getPublic privateKey

    fs
      .mkdir folderPath
      .catch -> it
      .then -> fs.writeFile privPath, privateKey
      .then -> fs.writeFile pubPath, publicKey
      .then -> console.log 'Created pub and private key', folderPath
      .catch ->
        console.log 'ERROR' it

  @deserialize = (name) ->
    address = new Address name
    address.load!
      .then -> address



module.exports = Address

Storage = require \./Storage
