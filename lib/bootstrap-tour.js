/* ============================================================
# Bootstrap-tour extended
#
# Copyright (c) 2013 FG Ribreau (@fgribreau)
# Licensed under the MIT, GPL licenses.
#
# Original version by http://sorich87.github.com/bootstrap-tour/
# ==============================================================
#
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

    Memory.prototype._avail = function() {
      return window.hasOwnProperty(this.ns);
    };

    Memory.prototype.setState = function(options, key, value) {
      if (!this._avail()) {
        return;
      }
      return window[this.ns][key] = value;
    };

    Memory.prototype.getState = function(options, key) {
      if (!this._avail()) {
        return;
      }
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
      var item;
      item = null;
      try {
        item = window.localStorage.getItem("" + this.ns + key);
        return JSON.parse(item);
      } catch (err) {
        console.error(err, item);
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
    /**
     * @module Public API
    */

    /**
     * Create a tour
     * @param  {Object} options An optional option object
     * @return {Tour}
    */

    function Tour(options) {
      var _this = this;
      this._options = $.extend(true, {}, Tour.defaults, options);
      this._setupEvents();
      this.persistence = new backend[this._options.persistence in backend ? this._options.persistence : "Memory"](this._options);
      this._steps = [];
      this.setCurrentStep();
      this._onresize(function() {
        if (!_this.ended) {
          return _this.showStep(_this._current);
        }
      });
    }

    /**
     * Add a step to the tour
     * @param {Object} step An optional object that describe the step
    */


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

    /**
     * Cleanly remove the Tour
    */


    Tour.prototype.dispose = function() {
      var _this = this;
      this._setState("current_step", null);
      this._setState("end", null);
      if (this._steps) {
        $.each(this._steps, function(i, s) {
          if ((s.element != null) && (s.element.popover != null)) {
            return s.element.popover("hide").removeData("popover");
          }
        });
      }
      $('.popover.bootstrap-tour, #bootstrap-tour-style, #bootstrap-tour-overlay').remove();
      $(document).off("click.bootstrap-tour, keyup.bootstrap-tour");
      this._evt.off();
      this.persistence.dispose();
      if (this._options.step) {
        $.each(this._options.step, function(k) {
          return _this._options.step[k] = null;
        });
      }
      return $.each(this._options, function(k) {
        return _this._options[k] = null;
      });
    };

    Tour.prototype.getStep = function(i) {
      if (this._steps[i] != null) {
        return $.extend({
          next: i === this._steps.length - 1 ? -1 : i + 1,
          prev: i - 1
        }, this._steps[i]);
      }
    };

    /**
     * Start tour from current step
     * @param  {Boolean} force If force is set to `true` the tour will be forced to start
     * @return {Promise}       Promise that will be resolved when the step is shown
    */


    Tour.prototype.start = function(force) {
      var def,
        _this = this;
      if (force == null) {
        force = false;
      }
      def = $.Deferred();
      if (this.ended() && !force) {
        return def.reject("Tour ended").promise();
      }
      $(document).off("click.bootstrap-tour", ".popover.bootstrap-tour .next").on("click.bootstrap-tour", ".popover.bootstrap-tour .next", function(e) {
        e.preventDefault();
        if (!$(e.currentTarget).is(':enabled')) {
          return;
        }
        return _this.next({
          trigger: 'popover'
        });
      });
      $(document).off("click.bootstrap-tour", ".popover.bootstrap-tour .prev").on("click.bootstrap-tour", ".popover.bootstrap-tour .prev", function(e) {
        e.preventDefault();
        if (!$(e.currentTarget).is(':enabled')) {
          return;
        }
        return _this.prev({
          trigger: 'popover'
        });
      });
      $(document).off("click.bootstrap-tour", ".popover.bootstrap-tour .end").on("click.bootstrap-tour", ".popover.bootstrap-tour .end", function(e) {
        e.preventDefault();
        if (!$(e.currentTarget).is(':enabled')) {
          return;
        }
        return _this.end({
          trigger: 'popover'
        });
      });
      this._setupKeyboardNavigation();
      this.showStep(this._current, def);
      return def.promise();
    };

    Tour.prototype.trigger = function(name, e) {
      if (e == null) {
        e = {};
      }
      this._evt.triggerHandler(this._initEvent(name, e));
      if (e.step) {
        return this._evt.triggerHandler(this._initEvent("" + name + ":step" + e.step.index, e));
      }
    };

    Tour.prototype.next = function(e) {
      var def,
        _this = this;
      if (e == null) {
        e = {};
      }
      def = e && e.def ? e.def : $.Deferred();
      this.hideStep(this._current, {
        trigger: e.trigger
      }).always(function() {
        return _this.showNextStep(def);
      });
      return def.promise();
    };

    Tour.prototype.prev = function(trigger) {
      var def,
        _this = this;
      if (trigger == null) {
        trigger = "api";
      }
      def = $.Deferred();
      this.hideStep(this._current, {
        trigger: trigger
      }).always(function() {
        return _this.showPrevStep(def);
      });
      return def.promise();
    };

    Tour.prototype.end = function(trigger) {
      var def, e, step,
        _this = this;
      if (trigger == null) {
        trigger = "api";
      }
      def = $.Deferred();
      step = this.getStep(this._current);
      e = {
        step: step,
        trigger: trigger
      };
      this.hideStep(this._current, e).always(function() {
        _this._setState("end", "yes");
        $(document).off(".bootstrap-tour");
        _this.trigger("end", e);
        return def.resolve();
      });
      return def.promise();
    };

    Tour.prototype.ended = function() {
      return !!this._getState("end");
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

    /**
     * Hide the specified step
     * @param  {Number} i  Step index
     * @param  {Event} e   Event
     * @return {Promise}
     * @optional
    */


    Tour.prototype.hideStep = function(i, e) {
      var $el, def, defs, step,
        _this = this;
      if (e == null) {
        e = {};
      }
      def = $.Deferred();
      step = e.step = this.getStep(i);
      $el = e.element = this.getElement(step.element);
      defs = [];
      this.trigger("hide", $.extend(e, {
        defs: defs
      }));
      $.when.apply($, defs).always(function() {
        if (step.reflex) {
          $el.css("cursor", "").off("click.tour");
        }
        $el.popover("hide");
        _this._toggleOverlay($el, false);
        _this.trigger("hidden", e);
        return def.resolve();
      });
      return def.promise();
    };

    /**
     * Show the specified step
     * @param  {Number} i     Step index
     * @param  {Deferred} def A deferred that will be resolved when the popover will be shown or reject if the step was not found
     * @optional
    */


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

    Tour.prototype.debugMode = function(activated) {
      var evtName, _i, _len, _ref, _results;
      _ref = ["show", "shown", "hide", "hidden", "end"];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        evtName = _ref[_i];
        _results.push(this.on(evtName, $.proxy(this._debug, this, evtName)));
      }
      return _results;
    };

    /**
     * @module Private API
    */


    /**
     * Debug callback
     * @param  {[type]} evtName [description]
     * @param  {[type]} e       [description]
     * @return {[type]}         [description]
    */


    Tour.prototype._debug = function(evtName, e) {
      return console.log(evtName, e.step.index, {
        details: e
      });
    };

    /**
     * Persist the state
     * @param {String} key
     * @param {Mixed} value
    */


    Tour.prototype._setState = function(key, value) {
      return this.persistence.setState(this._options, key, value);
    };

    Tour.prototype._getState = function(key) {
      var value;
      value = this.persistence.getState(this._options, key);
      return value;
    };

    /**
     * [_setupEvents description]
     * @return {[type]} [description]
    */


    Tour.prototype._setupEvents = function() {
      this._evt = $('<div/>');
      this.on = this._chainable(this._evt.on, this._evt);
      this.off = this._chainable(this._evt.off, this._evt);
      return this.one = this._chainable(this._evt.one, this._evt);
    };

    /**
     * Create a new (augmented) jQuery Event
     *
     * @description The augmented jQuery Event object contains:
     *  * `{String}` `trigger`:               `api | popover | reflex | keyboard`
     *  * `{Object}` `step`:                  the current step
     *  * `{jQuery}` `element`:               the current step element
     *  * `{Function}` `setPromise(promise)`: set the
     *  Note that `onShow` Event does not provides the `element` attribute use `onShown` instead)
     * @see Tour.event
     * @param  {String} name  Event name
     * @param  {Object} opt   Event attributes
     * @optional
     * @return {jQuery.Event} Augmented jQuery.Event
    */


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

    Tour.prototype._toggleOverlay = function($el, display) {
      var $overlay, pos;
      this._injectOverlay();
      $overlay = $('#bootstrap-tour-overlay');
      if (!display) {
        $el.removeClass('bootstrap-tour-expose').css('z-index', '1');
        pos = $el.data('old-pos');
        if (pos) {
          $el.css('position', pos).removeData('old-pos');
        }
        $('.popover.bootstrap-tour').removeClass('expose');
        $overlay.hide();
        return;
      }
      $el.addClass('bootstrap-tour-expose').css('z-index', '99999');
      pos = $el.css('position');
      if (pos !== 'absolute') {
        $el.data('old-pos', pos);
        $el.css('position', 'relative');
      }
      $('.popover.bootstrap-tour').addClass('expose').css('z-index', '99999');
      return $overlay.width($(document.body).outerWidth()).height(Math.max($(window).height(), $(document.body).outerHeight())).show();
    };

    Tour.prototype._injectOverlay = function() {
      if ($('style#bootstrap-tour-style').length > 0) {
        return;
      }
      $("<style id='bootstrap-tour-style' type='text/css'>" + (this._options.style()) + "</style>").appendTo('head');
      return $("<div id='bootstrap-tour-overlay'></div>").appendTo('body');
    };

    /**
     * Show step popover
     * @ignore
     * @param  {Object} step
     * @param  {Number} i    step number
    */


    Tour.prototype._showPopover = function(step, i) {
      var $el, $tmpl, options, popover, tip,
        _this = this;
      $el = this.getElement(step.element);
      options = $.extend(true, {}, this._options);
      step.content = this._getProp(step, options.step, "content", step);
      if (step.options) {
        $.extend(options, step.options);
      }
      if (this._getProp(step, options.step, "reflex", step)) {
        $el.css("cursor", "pointer").on("click.tour", function(e) {
          return _this.next({
            trigger: 'reflex'
          });
        });
      }
      step.content = this._getPropNotEmpty(step, options.step, "content", step);
      step.title = this._getPropNotEmpty(step, options.step, "title", step);
      $tmpl = $(this._getProp(step, options.step, "template", step)).wrapAll('<div/>').parent();
      if (step.prev === -1) {
        $tmpl.find('.prev').remove();
      }
      if (step.next === -1) {
        $tmpl.find('.next').remove();
      }
      $el.popover({
        placement: step.placement,
        trigger: "manual",
        template: $tmpl.html(),
        title: step.title || " ",
        content: step.content || " ",
        html: true,
        animation: step.animation
      });
      $tmpl.remove();
      popover = $el.data("popover");
      tip = popover.tip().addClass("bootstrap-tour " + options.name + "-step" + i + " " + options.step.addClass + " " + step.addClass);
      popover.show();
      this._toggleOverlay($el, this._getProp(step, options.step, "overlay", step));
      this._reposition(tip);
      return this._scrollIntoView(tip);
    };

    /**
     * Prevent popups from crossing over the edge of the window
     * @param  {jQuery} tip popover tip
    */


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

    /**
     * Scroll to the popup if it is not in the viewport
     * @param  {jQuery} tip popover tip
    */


    Tour.prototype._scrollIntoView = function(tip) {
      var tipRect;
      tipRect = tip.get(0).getBoundingClientRect();
      if (!(tipRect.top > 0 && tipRect.bottom < $(window).height() && tipRect.left > 0 && tipRect.right < $(window).width())) {
        return tip.get(0).scrollIntoView(true);
      }
    };

    /**
     * When the user resize the window
     * @ignore
     * @param  {Function} fn      Callback function
     * @param  {Number}   timeout How much time to wait after the last `resize` event before firing fn
    */


    Tour.prototype._onresize = function(fn, timeout) {
      return $(window).resize(function() {
        clearTimeout(timeout);
        return timeout = setTimeout(fn, 100);
      });
    };

    /**
     * Activate if necessary the keyboard navigation
    */


    Tour.prototype._setupKeyboardNavigation = function() {
      if (!this._options.keyboard) {
        return;
      }
      return $(document).on("keyup.bootstrap-tour", $.proxy(this._onKeyUp, this));
    };

    /**
     * When the key is up
     * @param  {Event} e jQuery event
     * @todo Handle escape key -> end the tour
     * @ignore
    */


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
            return this.next({
              trigger: "keyboard"
            });
          }
          break;
        case 37:
          e.preventDefault();
          if (step.prev !== -1 && this._current > 0) {
            return this.prev({
              trigger: "keyboard"
            });
          }
      }
    };

    /**
     * Execute sequentially the array of function
     * @param  {Array} arr  an array of function that return a promise
     * @param  {Object} ctx context
     * @ignore
     * @return {Deferred}
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
        @ignore
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

    /**
     * Get the a non `falsy` property `prop` from `obj1` if present or from obj2 otherwise and transfer
     * arguments `args` if the property is a function
     * @param  {Object} obj1    First object
     * @param  {Object} obj2    Second Object
     * @param  {String} prop    Property name
     * @param  {Array} args...  Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}
    */


    Tour.prototype._getPropNotEmpty = function() {
      var args, obj1, obj2, prop, test;
      obj1 = arguments[0], obj2 = arguments[1], prop = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
      test = function(o, prop) {
        return o && o.hasOwnProperty(prop) && !!o[prop];
      };
      return this.__getPropFn.apply(this, [test, obj1, obj2, prop].concat(__slice.call(args)));
    };

    /**
     * Get the a property `prop` from `obj1` if present or from obj2 otherwise and transfer
     * arguments `args` if the property is a function
     * @param  {Object} obj1    First object
     * @param  {Object} obj2    Second Object
     * @param  {String} prop    Property name
     * @param  {Array} args...  Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}
    */


    Tour.prototype._getProp = function() {
      var args, obj1, obj2, prop, test;
      obj1 = arguments[0], obj2 = arguments[1], prop = arguments[2], args = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
      test = function(o, prop) {
        return o && o.hasOwnProperty(prop);
      };
      return this.__getPropFn.apply(this, [test, obj1, obj2, prop].concat(__slice.call(args)));
    };

    /**
     * Get the a property `prop` from `obj1` if present or from obj2 otherwise and transfer
     * arguments `args` if the property is a function
     * @param  {Function} fn    The tester function
     * @param  {Object} obj1    First object
     * @param  {Object} obj2    Second Object
     * @param  {String} prop    Property name
     * @param  {Array} args...  Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}
    */


    Tour.prototype.__getPropFn = function() {
      var args, fn, obj1, obj2, prop;
      fn = arguments[0], obj1 = arguments[1], obj2 = arguments[2], prop = arguments[3], args = 5 <= arguments.length ? __slice.call(arguments, 4) : [];
      if (fn(obj1, prop)) {
        return this._execOrGet.apply(this, [obj1[prop]].concat(__slice.call(args)));
      } else if (fn(obj2, prop)) {
        return this._execOrGet.apply(this, [obj2[prop]].concat(__slice.call(args)));
      } else {
        return null;
      }
    };

    /**
     * Get the value of `val`, it handles the case when `val` is a function
     * @param  {Mixed} val Value
     * @param  {Array} arg Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}     `val` value
    */


    Tour.prototype._execOrGet = function() {
      var args, val;
      val = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if ($.isFunction(val)) {
        return val.apply(null, args);
      } else {
        return val;
      }
    };

    /**
     * Make a function chainable inside `Tour`
     * @param  {Function} fn  function
     * @param  {Object}   ctx Context
     * @return {Function}     Chainable function that returns the current Tour instance
     * @ignore
    */


    Tour.prototype._chainable = function(fn, ctx) {
      var _this = this;
      return function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        fn.apply(ctx, args);
        return _this;
      };
    };

    /**
     * `Tour` constructor `option` defaults
     * @type {Object}
    */


    Tour.defaults = {
      /**
       * This option is used to build the name of the cookie where the tour state is stored.
       * You can initialize several tours with different names in the same page and application.
       * @type {String}
      */

      name: "tour",
      /**
       * How to handle persistence
       *
       * @type {String} Backend name
       * @description The value can be "Cookie" | "LocalStorage" | "Memory" (default "Memory")
       *              Note: the "Cookie" backend requires jquery.cookie.js
      */

      persistence: "Memory",
      /**
       * Keyboard navigation
       * @type {Boolean} true if activated, false otherwise
      */

      keyboard: true,
      style: function() {
        return ".popover.bootstrap-tour.expose{z-index:99998;}\n#bootstrap-tour-overlay{background:rgba(0,0,0,0.5);display:none;width:100%;height:100%;position:absolute; top:0; left:0; z-index:99997;}";
      },
      step: {
        title: null,
        content: null,
        addClass: "",
        /**
         * Globally enable an overlay for each step element
         * @type {Boolean} true if activated, false otherwise
         * @todo Handle Bootstrap modal, pull requests are welcome !
        */

        overlay: false,
        reflex: false,
        /**
         * Bootstrap-tour template
         * @description Navigation template, `.prev`, `.next` and `.end`
         *              will be removed at runtime if necessary.
         *              The template can be an underscore template or $.tmpl ...
         *
         * @param  {Object} step The step to render
         * @return {String}      A string containing the HTML that will be injected into the popover
        */

        template: function(step) {
          return "<div class=\"popover\">\n  <div class=\"arrow\"></div>\n  <div class=\"popover-inner\"><h3 class=\"popover-title\"></h3>\n    <div class=\"popover-content\"></div>\n    <div class=\"modal-footer\">\n    <a href=\"#\" class=\"btn end\">End tour</a>\n    <a href=\"" + step.prev + "\" class=\"btn pull-right prev\">Previous</a>\n    <a href=\"" + step.next + "\" class=\"btn pull-right next\">Next</a>\n    </div>\n  </div>\n</div>";
        }
      }
    };

    return Tour;

  })();
  return window.Tour = Tour;
})(jQuery, window);
