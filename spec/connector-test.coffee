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
sinon = require 'sinon'
clerk = require '../lib/clerk'

Connector = clerk.Connector


describe 'Connector', ->

  describe '#constructor()', ->

    shouldUsePort = (options) ->
      connector = new Connector options
      port = options?.port or 5984
      it "should use port #{port}", ->
        assert.strictEqual connector.connector.port, port

    shouldUsePort()
    shouldUsePort {}
    shouldUsePort port: 8888





  describe '#close()', ->

    close = sinon.stub()
    callback = sinon.stub()
    connector = new Connector connector: close: close
    connector.close callback

    it 'should callback underlying connector.close', ->
      assert.ok close.calledOnce
      assert.ok close.calledWith callback





  describe '#request()', ->

    factory = ->
      requestObject = on: sinon.stub()
      request = sinon.stub().returns requestObject
      connector = new Connector connector: request: request

      context =
        connector: connector
        request: request
        requestObject: requestObject
        answer: connector.request.apply connector, arguments

    calledOnce = (context = {}) ->
      it 'once', ->
        { request } = context
        assert.ok request.calledOnce
      context

    withEmptyOptions = (context = {}) ->
      it 'with empty options', ->
        { request } = context
        arg0 = request.getCall(0).args[0]
        assert.strictEqual Object.keys(arg0).length, 0 if arg0
      context

    returningRequestObject = (context = {}) ->
      it 'returning request object', ->
        { answer, requestObject } = context
        assert.strictEqual answer, requestObject
      context

    describe 'with no options', ->
      describe 'should call connector.request', ->
        context = factory()
        calledOnce withEmptyOptions returningRequestObject context

    describe 'with data', ->
      data =
        message: 'Hello World!'
        fn: -> 'Goodbye World!'
      context = factory data: data
      context.data = data

      describe 'should call connector.request', ->
        calledOnce returningRequestObject context

        it 'with headers', ->
          { request } = context
          assert.ok headers = request.getCall(0).args[0].headers
          assert.strictEqual headers['Content-Type'], 'application/json'
          assert.ok headers['Content-Length'] > 0

        it 'with json parsable data', ->
          { request, data } = context
          js = null
          assert.ok json = request.getCall(0).args[0].data
          assert.doesNotThrow (-> js = JSON.parse(json) ), SyntaxError
          assert.strictEqual js.message, data.message
          assert.ok ///
            \b
              function (\s|\\n)* \(\) (\s|\\n)* \{ (\s|\\n)*
                \b return \b (\s|\\n)* 'Goodbye\sWorld!' (\s|\\n)* ; (\s|\\n)*
              \}
          ///.test(js.fn)

    describe 'with data emitter', ->
      data = on: sinon.stub()
      context = factory data: data

      describe 'should call connector.request', ->
        calledOnce returningRequestObject context

        it 'with data', ->
          { request } = context
          arg0 = request.getCall(0).args[0]
          assert.strictEqual arg0.data, data

    describe 'with callback', ->
      callback = sinon.stub()
      context = factory callback
      context.callback = callback

      describe 'should call connector.request', ->
        calledOnce withEmptyOptions returningRequestObject context

      describe 'should call request.on', ->
        { requestObject, callback } = context

        it 'with error callback', ->
          assert.ok requestObject.on.calledWith 'error', callback

        it 'with response callback', ->
          assert.ok requestObject.on.calledWith 'response'

        describe 'with response handler to', ->
          responseObject =
            on: sinon.stub()
            setEncoding: sinon.stub()

          responder = args[1] for args in requestObject.on.args when args[0] is 'response'
          responder(responseObject)

          it 'set encoding to utf8', ->
            responseObject.setEncoding.alwaysCalledWith 'utf8'

          it 'respond to data events', ->
            responseObject.on.calledWith 'data'

          it 'respond to end event', ->
            responseObject.on.calledWith 'end'

          it 'respond to error event', ->
            responseObject.on.calledWith 'error', responder

    describe 'head', ->
      callback = sinon.stub()

      headers = {}

      req = on: sinon.stub()
      res = on: sinon.stub(), setEncoding: sinon.stub(), headers: headers

      req.on.withArgs('response').yields res

      connector = new Connector
        connector:
          request: sinon.stub().returns req

      connector.request { method: 'HEAD' }, callback

      args[1]() for k, args of res.on.args when args[0] is 'end'

      it 'should set encoding to utf8', ->
        res.setEncoding.alwaysCalledWith 'utf8'

      it 'should return the headers as data', ->
        assert.ok callback.calledOnce
        assert.ok callback.alwaysCalledWith null, headers, res

    describe 'get', ->
      callback = sinon.stub()

      req = on: sinon.stub()
      res = on: sinon.stub(), setEncoding: sinon.stub()

      req.on.withArgs('response').yields res
      res.on.withArgs('data').yields '{"message":"Hello World!"}'

      connector = new Connector
        connector:
          request: sinon.stub().returns req

      connector.request { method: 'GET' }, callback

      args[1]() for k, args of res.on.args when args[0] is 'end'

      it 'should set encoding to utf8', ->
        res.setEncoding.alwaysCalledWith 'utf8'

      it 'should return JSON data', ->
        assert.ok callback.calledOnce
        assert.ok callback.alwaysCalledWith null, { message: 'Hello World!' }, res
