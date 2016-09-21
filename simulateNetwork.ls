spawn = require 'child_process' .spawn
exec = require 'child_process' .exec

exec 'rm -r /tmp/bootstrap /tmp/node*', ->

  spawn \lsc <[ . -v -p 5000 -b /tmp/bootstrap ]>

  setTimeout ->
    for i from 5001 til 5001 + (+process.argv[2] || 10)
      spawn \lsc [ \. \-p i, \-c 'localhost,5000' \-b "/tmp/node#{i}"]
  , 1000
