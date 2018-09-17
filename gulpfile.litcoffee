    gulp = require 'gulp'
    mustache = require 'gulp-mustache'
    rename = require 'gulp-rename'
    jsdom = require 'node-jsdom'
    request = require 'request-with-cookies'
    _ = require 'underscore'
    fs = require 'fs'
    gulpSequence = require 'gulp-sequence'

    config = require './config.json'

    loadSprint = (url, callback) ->
      console.log "Start load #{url}"
      options =
        url: url
        cookies: [
          {
            name: '_redmine_session'
            value: config.cookie
          }
        ]

      client = request.createClient options
      client options.url, (error, response, body) ->
        if response.statusCode != 200
          console.error "Sprint #{url} not loaded"
          return callback()
        jsdom.env body, ["http://code.jquery.com/jquery.js"], (e, window) ->
          if e
            console.error 'e', e
            return callback()
          $ = window.$
          values = window.$ 'div.t:contains("' + config.name + '")'
          values = _.map values, (value) -> $(value).closest '.issue'
          values = _.map values, (value) -> $(value).find '.subject'
          values = _.map values, (value) -> $(value).text().split('\n').join ' '
          values = _.map values, (value) ->
            caption: value
            closeButton: true
            urls: [
              {
                caption: 'demo'
                href: ''
              }
            ]
          console.log "Sprint #{url} loaded"
          callback values

    gulp.task 'default', gulpSequence 'load-tasks', 'generate'

    gulp.task 'generate', (cb) ->
      tasks = require('./tasks.json').tasks
      tasks = _.map tasks, (value) ->
        value.urls = _.filter value.urls, (url) -> !!url.href
        value

      gulp.src "./templates/*.mustache"
        .pipe(mustache(tasks: tasks))
        .pipe(rename((path) -> path.extname = '.html'))
        .pipe(gulp.dest(config.output))


    gulp.task 'load-tasks', (cb) ->

      load = (urls, tasks = []) ->
        [first, other...] = urls

        if first
          loadSprint first, (loadedTasks = []) ->
            load other, tasks.concat loadedTasks
          return

        content = JSON.stringify {tasks: tasks}, null, 2
        fs.writeFile "./tasks.json", content, 'utf8', (err) ->
          if err
            cb()
            return console.log(err)
          console.log "The file was saved!"
          cb()

      load config.sprintUrls
      return
