spawn = require 'child_process' .spawn
exec = require 'child_process' .exec

nbNodes = if +process.argv[2] != null => +process.argv[2] else 10

exec 'rm -r /tmp/bootstrap /tmp/node*', ->

  console.log 'Spawning bootstrap'
  spawn \lsc <[ . -v -p 6000 -b /tmp/bootstrap ]>

  setTimeout ->

    for let i from 6001 til 6001 + nbNodes
      setTimeout ->
        node = spawn \lsc [ \. \-p i, \-v \-c 'localhost,6000' \-b "/tmp/node#{i}"]
        node.stdout.on \data ->
          console.log i - 6000, it.toString!
        console.log 'Spawning' i
        if i is 6000 + nbNodes
          console.log 'Ready'
      , (i - 6000) * 500

  , 500
