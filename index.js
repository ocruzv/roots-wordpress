// Generated by CoffeeScript 1.10.0
(function() {
  var API, RootsUtil, W, _, add_posts_to_locals, add_urls_to_posts, path, render_single_views, request;

  API = require('./api');

  W = require('when');

  RootsUtil = require('roots-util');

  _ = require('lodash');

  path = require('path');

  module.exports = function(opts) {
    var RootsWordpress;
    if (opts == null) {
      opts = {};
    }
    if (!opts.site) {
      throw new Error('You must supply a site url or id');
    }
    if (!opts.post_types) {
      opts.post_types = {
        post: {}
      };
    }
    return RootsWordpress = (function() {
      function RootsWordpress(roots) {
        this.roots = roots;
        this.util = new RootsUtil(this.roots);
        opts.site = opts.site.replace(/http:\/\//, '');
      }

      RootsWordpress.prototype.setup = function() {
        var all, base, config, type;
        if ((base = this.roots.config).locals == null) {
          base.locals = {};
        }
        this.roots.config.locals.wordpress = {};
        all = (function() {
          var ref, results;
          ref = opts.post_types;
          results = [];
          for (type in ref) {
            config = ref[type];
            results.push(request(opts.site, type, config)
            .then(get_posts_and_routes.bind(this, type))
            .then(add_urls_to_posts)
            .then(add_posts_to_locals.bind(this, type))
            .then(render_single_views.bind(this, config, type)));
          }
          return results;
        }).call(this);
        return W.all(all);
      };

      return RootsWordpress;

    })();
  };

  request = function(site, type, config) {
    var params, pathName;
    pathName = site + "/posts";
    if (type === "categories") {
      pathName = site + "/categories";
    }
    params = _.merge(config, {
      type: type
    });
    return API({
      path: pathName,
      params: params
    });
  };

  get_posts_and_routes = function(type, res) {
    var posts;
    if (type === "categories") {
      posts = res.entity.categories;
    } else {
      posts = res.entity.posts;
    }
    if(type === "categories") {
      return {
        urls: [],
        posts: posts
      }
    }
    return W.map(posts, (function(_this) {
      return function(p) {
        var output;

        output = "/" + type + "/" + p.slug + ".html";

        return output;
      }
    })(this)).then(function(urls) {
      return {
        urls: urls,
        posts: posts
      };
    });
  };

  render_single_views = function(config, type, posts) {
    if (!config.template) {
      return posts
    }
    return W.map(posts, (function(_this) {
      return function(p) {
        var compiler, locals, output, tpl;
        tpl = path.join(_this.roots.root, config.template);
        locals = _.merge(_this.roots.config.locals, {
          post: p
        });
        output = type + "/" + p.slug + ".html";
        compiler = _.find(_this.roots.config.compilers, function(c) {
          return _.contains(c.extensions, path.extname(tpl).substring(1));
        });
        return compiler.renderFile(tpl, locals).then(function(res) {
          return _this.util.write(output, res.result);
        })["yield"](output);
      };
    })(this)).then(function(urls) {
      return posts;
    });
  };

  add_urls_to_posts = function(obj) {
    return obj.posts.map(function(post, i) {
      post._url = obj.urls[i];
      return post;
    });
  };

  add_posts_to_locals = function(type, posts) {
    var parents;
    if (type === "categories") {
      parents = posts.filter(function(category) {
        if (category.parent === 0) {
          category.childs = [];
          return category;
        }
      });
      posts.forEach(function(category) {
        if (category.parent !== 0) {
          return parents.forEach(function(parent) {
            if (parent.ID === category.parent) {
              return parent.childs.push(category);
            }
          });
        }
      });
      return this.roots.config.locals.wordpress[type] = parents;
    } else {
      return this.roots.config.locals.wordpress[type] = posts;
    }
  };

}).call(this);
