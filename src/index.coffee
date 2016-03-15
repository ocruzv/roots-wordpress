API       = require './api'
W         = require 'when'
RootsUtil = require 'roots-util'
_         = require 'lodash'
path      = require 'path'
async     = require 'async'

module.exports = (opts = {}) ->
  if not opts.site then throw new Error('You must supply a site url or id')
  if not opts.post_types then opts.post_types = { post: {} }

  class RootsWordpress
    constructor: (@roots) ->
      @util = new RootsUtil(@roots)

    setup: ->
      @roots.config.locals ?= {}
      @roots.config.locals.wordpress = {}

      all = for type, config of opts.post_types
        request(opts.site, type, config)
          .then(get_posts_and_routes.bind(@, type))
          .then(add_urls_to_posts)
          .then(add_posts_to_locals.bind(@, type))
          .then(render_single_views.bind(@, config, type))

      W.all(all)

# private

request = (site, type, config) ->
  if !config.route
    config.route = "posts"
  pathName = site + config.route

  # params = _.merge(config, type: type)
  API(path: pathName, params: config.apiParams)

get_posts_and_routes = (type, res) ->
  posts = res.entity
  if type == "categories"
    return {
      urls: [],
      posts: posts
    }

  W.map posts, (p) =>
    output = "/#{type}/#{p.slug}.html"

    return output
  .then (urls) -> { urls: urls, posts: posts }

render_single_views = (config, type, posts) ->

  if not config.template then return posts

  async.eachSeries posts, (post, callback) =>
    tpl = path.join(@roots.root, config.template)
    locals = @roots.config.locals
    locals.post = post
    output = "#{type}/#{post.slug}.html"

    compiler = _.find @roots.config.compilers, (c) ->
      _.contains(c.extensions, path.extname(tpl).substring(1))

    compiler.renderFile(tpl, locals)
      .then((res) => _this.util.write(output, res.result))
      .then(-> callback null)

add_urls_to_posts = (obj) ->
  obj.posts.map (post, i) ->
    post._url = obj.urls[i]
    post

add_posts_to_locals = (type, posts) ->
  @roots.config.locals.wordpress[type] = posts
