path = require 'path'
{ _buildOptions, normalizeConfig, loadSpecificMigrationsFromDir } = require '../src/utils'

describe 'Utils', ->

    describe '_buildOptions', ->

        it 'should allow custom options and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    a: 1
            _buildOptions(config).should.be.deepEqual({
                a: 1
                server: poolSize: 5
            })
            done()

        it 'should allow deeply nested options and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    a: b: 'c'
            _buildOptions(config).should.be.deepEqual({
                a: b: 'c'
                server: poolSize: 5
            })
            done()

        it 'should normalize null options and set the default `poolSize` of 5', (done) ->
            config = { otherKey: 'x' }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 5 })
            done()

        it 'should properly merge the `server` key and set the default `poolSize` of 5', (done) ->
            config =
                options:
                    server: x: 1
            _buildOptions(config).should.be.deepEqual({
                server:
                    poolSize: 5
                    x: 1
            })
            done()

        it 'should not override the `poolSize` if only set in `server`', (done) ->
            config =
                options:
                    server:
                        x: 1
                        poolSize: 4
            _buildOptions(config).should.be.deepEqual({
                server:
                    poolSize: 4
                    x: 1
            })
            done()

        it '[compat] should normalize null options and set the custom `poolSize`', (done) ->
            config = { otherKey: 'x', poolSize: 7 }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 7 })
            done()

        it '[compat] should support `poolSize` with null options', (done) ->
            config = { otherKey: 'x', poolSize: 2 }
            _buildOptions(config).should.be.deepEqual({ server: poolSize: 2 })
            done()

        it '[compat] should override the `poolSize` if provided as a separate option', (done) ->
            config = {
                options:
                    server:
                        x: 1
                        poolSize: 2
                poolSize: 4
            }
            _buildOptions(config).should.be.deepEqual({
                server:
                    x: 1
                    poolSize: 4
            })
            done()


    describe 'normalizeConfig', ->
        it 'should throw without config', (done) ->
            normalizeConfig.should.throw('`config` is not provided or is not an object')
            done()

        it 'should allow config with proper url', (done) ->
          config =
            url: 'mongodb://aaa.bb.ccc:27101/some-db?ssl=true'

          normalizeConfig(config).should.be.deepEqual(config)
          done()

        it 'should set default collection', (done) ->
          config =
            url: 'mongodb://aaa.bb.ccc:27101/some-db?ssl=true'

          normalizeConfig(config).collection.should.be.equal('_migrations')
          done()

        it 'should throw with wrong replicaset 1', (done) ->
            normalizeConfig.bind(null, {
                replicaset: 7
            }).should.throw('`replicaset` is not an object')
            done()

        it 'should throw with wrong replicaset 2', (done) ->
            normalizeConfig.bind(null, {
                replicaset: {}
            }).should.throw('`replicaset.name` is not set')
            done()

        it 'should throw with wrong replicaset 3', (done) ->
            normalizeConfig.bind(null, {
                replicaset: {
                    name: 'x'
                }
            }).should.throw('`replicaset.members` is not set or is not an array')
            done()

        it 'should throw with wrong replicaset 4', (done) ->
            normalizeConfig.bind(null, {
                replicaset: {
                    name: 'x',
                    members: 'lol'
                }
            }).should.throw('`replicaset.members` is not set or is not an array')
            done()

        it 'should throw with wrong replicaset 5', (done) ->
            normalizeConfig.bind(null, {
                replicaset: {
                    name: 'x',
                    members: [{ xost: 'x' }]
                }
            }).should.throw('each of `replicaset.members` must have `host` set')
            done()

        it 'should throw without host and replicaset', (done) ->
            normalizeConfig.bind(null, {
            }).should.throw('`host` is required when `replicaset` is not set')
            done()

        it 'should throw without db', (done) ->
            normalizeConfig.bind(null, {
                host: 'localhost'
            }).should.throw('`db` is not set')
            done()

        it 'should throw with password but without username', (done) ->
            normalizeConfig.bind(null, {
                host: 'localhost',
                db: '_mm',
                password: 'very secret password'
            }).should.throw('`password` provided but `user` is not')
            done()

    describe 'loadSpecificMigrationsFromDir', ->
      dir = path.join __dirname, 'migrations'
      
      it 'should find existing migrations by number', (done) ->
        loadSpecificMigrationsFromDir dir, [ '1' ], (err, migrations) ->
          (!err).should.be.ok()
          (migrations).should.be.ok()
          migrations.length.should.be.equal(1)
          migrations[0].id.should.be.equal('test1')
          done()

      it 'should find existing migrations by id', (done) ->
        loadSpecificMigrationsFromDir dir, [ 'test1' ], (err, migrations) ->
          (!err).should.be.ok()
          (migrations).should.be.ok()
          migrations.length.should.be.equal(1)
          migrations[0].id.should.be.equal('test1')
          done()

      it 'should find existing migrations by full file name', (done) ->
        loadSpecificMigrationsFromDir dir, [ '1-test1.js' ], (err, migrations) ->
          (!err).should.be.ok()
          (migrations).should.be.ok()
          migrations.length.should.be.equal(1)
          migrations[0].id.should.be.equal('test1')
          done()

      it 'should find several migrations and keep the order', (done) ->
        loadSpecificMigrationsFromDir dir, [ '3', 'test1' ], (err, migrations) ->
          (!err).should.be.ok()
          (migrations).should.be.ok()
          migrations.length.should.be.equal(2)
          migrations[0].id.should.be.equal('test3')
          migrations[1].id.should.be.equal('test1')
          done()
