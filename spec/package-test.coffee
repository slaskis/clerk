#
#   Copyright 2011 Michael Phan-Ba
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#


assert = require 'assert'
clerk = require '../lib/clerk'
fs = require 'fs'





describe 'package', ->





  describe 'JSON', ->

    pkg = JSON.parse fs.readFileSync "#{__dirname}/../package.json", 'utf8'

    it 'should have the same version as clerk.js', ->
      assert.equal pkg.version, clerk.version





  describe 'history', ->

    history = fs.readFileSync "#{__dirname}/../HISTORY.md", 'utf8'

    it 'should have an entry for the current version', ->
      assert.ok !!~history.indexOf(clerk.version)
