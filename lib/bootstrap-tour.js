/* ============================================================
# bootstrap-tour.js v0.1
# http://sorich87.github.com/bootstrap-tour/
# ==============================================================
#
# Copyright (c) 2013 FG Ribreau
# Licensed under the MIT, GPL licenses.
*/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

(function($, window) {
  var Backend, Cookie, LocalStorage, Memory, Tour, backend, document;
  document = window.document;
  Backend = (function() {

    function Backend() {}

    Backend.prototype.dispose = function() {};

    Backend.prototype.setState = function(options, key, value) {};

    Backend.prototype.getState = function(options, key) {};

    return Backend;

  })();
  Memory = (function(_super) {

    __extends(Memory, _super);

    function Memory(options) {
      this.ns = "__db_" + options.name + "__";
      window[this.ns] = {};
    }

    Memory.prototype.setState = function(options, key, value) {
      return window[this.ns][key] = value;
    };

    Memory.prototype.getState = function(options, key) {
      return window[this.ns][key] || null;
    };

    Memory.prototype.dispose = function() {
      return delete window[this.ns];
    };

    return Memory;

  })(Backend);
  Cookie = (function(_super) {

    __extends(Cookie, _super);

    function Cookie(options) {
      this.ns = "" + options.name + "_";
    }

    Cookie.prototype.setState = function(options, key, value) {
      return $.cookie("" + this.ns + key, value, {
        expires: 36500,
        path: '/'
      });
    };

    Cookie.prototype.getState = function(options, key) {
      return $.cookie("" + this.ns + key);
    };

    return Cookie;

  })(Backend);
  LocalStorage = (function(_super) {

    __extends(LocalStorage, _super);

    function LocalStorage(options) {
      this.ns = "" + options.name + "_";
    }

    LocalStorage.prototype.setState = function(options, key, value) {
      return window.localStorage.setItem("" + this.ns + key, JSON.stringify(value));
    };

    LocalStorage.prototype.getState = function(options, key) {
      try {
        return JSON.parse(window.localStorage.getItem("" + this.ns + key));
      } catch (err) {
        console.error(err);
        return null;
      }
    };

    return LocalStorage;

  })(Backend);
  backend = {
    Memory: Memory,
    Cookie: Cookie,
    LocalStorage: LocalStorage
  };
  Tour = (function() {

    function Tour(options) {
      var _this = this;
      this._options = $.extend(true, {}, Tour.defaults, options);
      this._evt = $('<div/>');
      this.on = this._chainable(this._evt.on, this._evt);
      this.off = this._chainable(this._evt.off, this._evt);
      this.one = this._chainable(this._evt.one, this._evt);
      this.persistence = new backend[this._options.persistence in backend ? this._options.persistence : "Memory"](this._options);
      this._steps = [];
      this.setCurrentStep();
      this._onresize(function() {
        if (!_this.ended) {
          return _this.showStep(_this._current);
        }
      });
    }

    Tour.prototype.dispose = function() {
      var _this = this;
      this._setState("current_step", null);
      this._setState("end", null);
      $.each(this._steps, function(i, s) {
        if ((s.element != null) && (s.element.popover != null)) {
          return s.element.popover("hide").removeData("popover");
        }
      });
      $('.popover').remove();
      $.each(this._options.step, function(k) {
        return _this._options.step[k] = null;
      });
      this._evt.unbind();
      this.persistence.dispose();
      return $.each(this._options, function(k) {
        return _this._options[k] = null;
      });
    };

    Tour.prototype._setState = function(key, value) {
      this.persistence.setState(this._options, key, value);
      return this._options.afterSetState(key, value);
    };

    Tour.prototype._getState = function(key) {
      var value;
      value = this.persistence.getState(this._options, key);
      this._options.afterGetState(key, value);
      return value;
    };

    Tour.prototype.addStep = function(step) {
      this._steps.push($.extend({
        index: this._steps.length,
        path: "",
        element: null,
        placement: "right",
        title: "",
        content: "",
        animation: true,
        reflex: false,
        addClass: ""
      }, step));
      return this;
    };

    Tour.prototype.getStep = function(i) {
      if (this._steps[i] != null) {
        return $.extend({
          next: i === this._steps.length - 1 ? -1 : i + 1,
          prev: i - 1
        }, this._steps[i]);
      }
    };

    Tour.prototype.start = function(force) {
      var def,
        _this = this;
      if (force == null) {
        force = false;
      }
      def = $.Deferred();
      if (this.ended() && !force) {
        return def.fail("Tour ended").promise();
      }
      $(document).off("click.bootstrap-tour", ".popover .next").on("click.bootstrap-tour", ".popover .next", function(e) {
        e.preventDefault();
        return _this.next({
          trigger: 'popover'
        });
      });
      $(document).off("click.bootstrap-tour", ".popover .prev").on("click.bootstrap-tour", ".popover .prev", function(e) {
        e.preventDefault();
        return _this.prev({
          trigger: 'popover'
        });
      });
      $(document).off("click.bootstrap-tour", ".popover .end").on("click.bootstrap-tour", ".popover .end", function(e) {
        e.preventDefault();
        return _this.end({
          trigger: 'popover'
        });
      });
      this._setupKeyboardNavigation();
      this.showStep(this._current, def);
      return def.promise();
    };

    Tour.prototype.trigger = function(name, opt) {
      return this._evt.triggerHandler(this._initEvent(name, opt));
    };

    Tour.prototype._initEvent = function(name, opt) {
      var defs, e, step;
      if (name == null) {
        name = "";
      }
      if (opt == null) {
        opt = {};
      }
      e = jQuery.Event(name);
      $.extend(e, opt);
      if (e.defs) {
        defs = e.defs;
        e.setPromise = function(promise) {
          return defs.push(promise);
        };
        delete e.defs;
      }
      if (!e.trigger) {
        e.trigger = "api";
      }
      if (!e.step) {
        step = e.step = this.getStep(this._current);
      }
      if (name === "show" || name.indexOf("show:") === 0) {
        delete e.element;
      } else if (step) {
        e.element = this.getElement(step.element);
      }
      return e;
    };

    Tour.prototype.next = function(e) {
      var def;
      def = e && e.def ? e.def : $.Deferred();
      this.hideStep(this._current, e);
      this.showNextStep(def);
      return def.promise();
    };

    Tour.prototype.prev = function(e) {
      var def;
      def = e && e.def ? e.def : $.Deferred();
      this.hideStep(this._current, e);
      this.showPrevStep(def);
      return def.promise();
    };

    Tour.prototype.end = function(e) {
      var step;
      this.hideStep(this._current, e);
      $(document).off(".bootstrap-tour");
      this._setState("end", "yes");
      step = this.getStep(this._current);
      if (step && (step.onEnd != null)) {
        step.onEnd(this, e);
      }
      if (this._options.step.onEnd !== step.onEnd) {
        return this._options.step.onEnd(this, e);
      }
    };

    Tour.prototype.ended = function() {
      return !!this._getState("end");
    };

    /*
        Execute sequentially the array of function
        @param  {Array} arr Array of function that return a promise
        @param  {Object} ctx (optional)
        @return {Deferred}
    */


    Tour.prototype._when = function(arr, ctx) {
      var def, next;
      def = $.Deferred();
      next = function() {
        var fn;
        fn = arr.shift();
        if (!fn) {
          return def.resolve();
        }
        return fn.call(ctx).then(next);
      };
      next();
      return def.promise();
    };

    /*
        Returns an array of `ipt` `times` times
        @param  {[type]} count [description]
        @param  {[type]} ipt   [description]
        @return {[type]}       [description]
    */


    Tour.prototype._mapTimes = function(times, ipt) {
      var o;
      o = [];
      while (times--) {
        o.push(ipt);
      }
      return o;
    };

    /*
        Goto a step by its index
    */


    Tour.prototype.gotoStep = function(index) {
      return this._when(this._mapTimes(index, this.next), this);
    };

    Tour.prototype.restart = function() {
      this._setState("current_step", null);
      this._setState("end", null);
      this.setCurrentStep(0);
      return this.start();
    };

    Tour.prototype.getElement = function(el) {
      if (typeof el === 'function') {
        el = el();
      }
      if (!el) {
        return $();
      }
      if (el instanceof jQuery) {
        return el;
      }
      return $(el);
    };

    Tour.prototype.hideStep = function(i, e) {
      var $el, step;
      if (e == null) {
        e = {};
      }
      step = e.step = this.getStep(i);
      $el = e.element = this.getElement(step.element);
      this.trigger("hide", e);
      this.trigger("hide:step" + step.index, e);
      if (step.reflex) {
        $el.css("cursor", "").off("click.tour");
      }
      return $el.popover("hide");
    };

    Tour.prototype._deferred = function(d) {
      if (d && d.done) {
        return d;
      }
      return $.Deferred().resolve().promise();
    };

    Tour.prototype.showStep = function(i, def) {
      var defs, step,
        _this = this;
      step = this.getStep(i);
      if (!step) {
        if (def) {
          def.reject("Step " + i + " undefined");
        }
        return;
      }
      this.setCurrentStep(i);
      if (step.path !== "" && document.location.pathname !== step.path && document.location.pathname.replace(/^.*[\\\/]/, '') !== step.path) {
        document.location.href = step.path;
        return;
      }
      defs = [];
      this.trigger("show", {
        step: step,
        element: false,
        defs: defs
      });
      this.trigger("show:step" + step.index, {
        step: step,
        element: false,
        defs: defs
      });
      return $.when.apply($, defs).always(function() {
        var $el;
        $el = _this.getElement(step.element);
        if ($el.length === 0 || !$el.is(":visible")) {
          _this.trigger("skipping", {
            element: $el,
            step: step
          });
          _this.next({
            def: def
          });
          return;
        }
        _this._showPopover(step, i);
        _this.trigger("shown", {
          step: step,
          element: $el
        });
        _this.trigger("shown:step" + step.index, {
          step: step,
          element: $el
        });
        if (def) {
          return def.resolve();
        }
      });
    };

    Tour.prototype.setCurrentStep = function(value) {
      if (value != null) {
        this._current = value;
        return this._setState("current_step", value);
      } else {
        this._current = this._getState("current_step");
        if (!this._current || this._current === "null") {
          return this._current = 0;
        } else {
          return this._current = parseInt(this._current, 10);
        }
      }
    };

    Tour.prototype.showNextStep = function(def) {
      var step;
      step = this.getStep(this._current);
      return this.showStep(step.next, def);
    };

    Tour.prototype.showPrevStep = function(def) {
      var step;
      step = this.getStep(this._current);
      return this.showStep(step.prev, def);
    };

    Tour.prototype._showPopover = function(step, i) {
      var $el, $nav, content, options, popover, tip,
        _this = this;
      $el = this.getElement(step.element);
      options = $.extend(true, {}, this._options);
      if (step.options) {
        $.extend(options, step.options);
      }
      if (step.reflex) {
        $el.css("cursor", "pointer").on("click.tour", function(e) {
          return _this.next({
            trigger: 'reflex'
          });
        });
      }
      step.content = this._getProp(step, options.step, "content", step);
      $nav = $(options.template(step)).wrapAll('<div/>').parent();
      if (step.prev === -1) {
        $nav.find('.prev').remove();
      }
      if (step.next === -1) {
        $nav.find('.next').remove();
      }
      content = $nav.html();
      $nav.remove();
      $el.popover({
        placement: step.placement,
        trigger: "manual",
        title: this._getProp(step, options.step, "title", step),
        content: content,
        html: true,
        animation: step.animation
      });
      popover = $el.data("popover");
      tip = popover.tip().addClass("bootstrap-tour " + options.name + "-step" + i + " " + options.step.addClass + " " + step.addClass);
      popover.show();
      this._reposition(tip);
      return this._scrollIntoView(tip);
    };

    Tour.prototype._reposition = function(tip) {
      var offsetBottom, offsetRight, tipOffset;
      tipOffset = tip.offset();
      offsetBottom = $(document).outerHeight() - tipOffset.top - $(tip).outerHeight();
      if (offsetBottom < 0) {
        tipOffset.top = tipOffset.top + offsetBottom;
      }
      offsetRight = $(document).outerWidth() - tipOffset.left - $(tip).outerWidth();
      if (offsetRight < 0) {
        tipOffset.left = tipOffset.left + offsetRight;
      }
      if (tipOffset.top < 0) {
        tipOffset.top = 0;
      }
      if (tipOffset.left < 0) {
        tipOffset.left = 0;
      }
      return tip.offset(tipOffset);
    };

    Tour.prototype._scrollIntoView = function(tip) {
      var tipRect;
      tipRect = tip.get(0).getBoundingClientRect();
      if (!(tipRect.top > 0 && tipRect.bottom < $(window).height() && tipRect.left > 0 && tipRect.right < $(window).width())) {
        return tip.get(0).scrollIntoView(true);
      }
    };

    Tour.prototype._onresize = function(cb, timeout) {
      return $(window).resize(function() {
        clearTimeout(timeout);
        return timeout = setTimeout(cb, 100);
      });
    };

    Tour.prototype._setupKeyboardNavigation = function() {
      if (!this._options.keyboard) {
        return;
      }
      return $(document).on("keyup.bootstrap-tour", $.proxy(this._onKeyUp, this));
    };

    Tour.prototype._onKeyUp = function(e) {
      var step;
      if (!e.which) {
        return;
      }
      step = this.getStep(this._current);
      if (!step) {
        return;
      }
      switch (e.which) {
        case 39:
          e.preventDefault();
          if (step.next !== -1 && this._current < this._steps.length - 1) {
            return this.next();
          }
          break;
        case 37:
          e.preventDefault();
          if (step.prev !== -1 && this._current > 0) {
            return this.prev();
          }
      }
    };

    Tour.prototype._execOrGet = function(val, arg) {
      if ($.isFunction(val)) {
        return val(arg);
      } else {
        return val;
      }
    };

    Tour.prototype._getProp = function() {
      var args, obj, obj2, prop;
      obj = arguments[0], obj2 = arguments[1], prop = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
      if (obj[prop]) {
        return this._execOrGet.apply(this, [obj[prop]].concat(__slice.call(args)));
      } else {
        return this._execOrGet.apply(this, [obj2[prop]].concat(__slice.call(args)));
      }
    };

    Tour.prototype._chainable = function(fn, ctx) {
      var _this = this;
      return function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        fn.apply(ctx, args);
        return _this;
      };
    };

    Tour.defaults = {
      name: "tour",
      persistence: "Memory",
      keyboard: true,
      template: function(step) {
        return "<p>" + step.content + "</p>\n<hr/>\n<p>\n  <a href=\"" + step.prev + "\" class=\"prev\">Previous</a>\n  <a href=\"" + step.next + "\" class=\"next\">Next</a>\n  <a href=\"#\" class=\"pull-right end\">End tour</a>\n</p>";
      },
      afterSetState: function(key, value) {},
      afterGetState: function(key, value) {},
      step: {
        title: null,
        content: null,
        addClass: "",
        onShow: function(tour, event) {},
        onShown: function(tour, event) {},
        onHide: function(tour, event) {},
        onEnd: function(tour, event) {}
      }
    };

    return Tour;

  })();
  return window.Tour = Tour;
})(jQuery, window);
