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
      opts.site = opts.site.replace(/http:\/\//, '')

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
  pathName = "#{site}/posts"
  if type == "categories"
    pathName = "#{site}/categories"
  params = _.merge(config, type: type)
  API(path: pathName, params: params)

get_posts_and_routes = (type, res) ->
  if type == "categories"
    posts = res.entity.categories
    return {
      urls: [],
      posts: posts
    }
  else
    posts = res.entity.posts

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
  if type == "categories"
    parents = posts.filter (category) ->
      if category.parent == 0
        category.childs = []
        return category

    posts.forEach (category) ->
      if category.parent != 0
        parents.forEach (parent) ->
          if parent.ID == category.parent
            parent.childs.push category

    @roots.config.locals.wordpress[type] = parents
  else
    @roots.config.locals.wordpress[type] = posts
