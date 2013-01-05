/* ============================================================
# bootstrap-tour.js v0.1
# http://sorich87.github.com/bootstrap-tour/
# ==============================================================
#
# Copyright (c) 2013 FG Ribreau
# Licensed under the MIT, GPL licenses.
*/

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function($, window) {
  var Backend, Cookie, LocalStorage, Memory, Tour, backend, document;
  document = window.document;
  Backend = (function() {

    function Backend() {}

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
      this._options = $.extend({}, Tour.defaults, options);
      this.persistence = new backend[this._options.persistence in backend ? this._options.persistence : "Memory"](this._options);
      this._steps = [];
      this.setCurrentStep();
      this._onresize(function() {
        if (!_this.ended) {
          return _this.showStep(_this._current);
        }
      });
    }

    Tour.prototype.setState = function(key, value) {
      this.persistence.setState(this._options, key, value);
      return this._options.afterSetState(key, value);
    };

    Tour.prototype.getState = function(key) {
      var value;
      value = this.persistence.getState(this._options, key);
      this._options.afterGetState(key, value);
      return value;
    };

    Tour.prototype.addStep = function(step) {
      return this._steps.push(step);
    };

    Tour.prototype.getStep = function(i) {
      if (this._steps[i] != null) {
        return $.extend({
          path: "",
          element: null,
          placement: "right",
          title: "",
          content: "",
          next: i === this._steps.length - 1 ? -1 : i + 1,
          prev: i - 1,
          animation: true,
          reflex: false,
          addClass: "",
          onShow: function(tour, event) {},
          onShown: function(tour, event) {},
          onHide: function(tour, event) {}
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

    Tour.prototype._initEvent = function(e) {
      var step;
      if (e == null) {
        e = {};
      }
      if (!e.trigger) {
        e.trigger = "api";
      }
      step = this.getStep(this._current);
      if (e.element === false) {
        delete e.element;
      } else if (step) {
        e.element = this.getElement(step.element);
      }
      return e;
    };

    Tour.prototype.next = function(e) {
      var def,
        _this = this;
      def = $.Deferred();
      this.hideStep(this._current, this._initEvent(e));
      setTimeout(function() {
        return _this.showNextStep(def);
      }, 0);
      return def.promise();
    };

    Tour.prototype.prev = function(e) {
      var def,
        _this = this;
      def = $.Deferred();
      this.hideStep(this._current, this._initEvent(e));
      setTimeout(function() {
        return _this.showPrevStep(def);
      }, 0);
      return def.promise();
    };

    Tour.prototype.end = function(e) {
      this.hideStep(this._current, this._initEvent(e));
      $(document).off(".bootstrap-tour");
      return this.setState("end", "yes");
    };

    Tour.prototype.ended = function() {
      return !!this.getState("end");
    };

    Tour.prototype.restart = function() {
      this.setState("current_step", null);
      this.setState("end", null);
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
      if (!e) {
        e = this._initEvent();
      }
      step = this.getStep(i);
      $el = this.getElement(step.element);
      if (step.onHide != null) {
        step.onHide(this, e);
      }
      if (this._options.onHide !== step.onHide) {
        this._options.onHide(this, e);
      }
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
      var defs, e, step,
        _this = this;
      step = this.getStep(i);
      if (!step) {
        if (def) {
          def.reject();
        }
        return;
      }
      this.setCurrentStep(i);
      if (step.path !== "" && document.location.pathname !== step.path && document.location.pathname.replace(/^.*[\\\/]/, '') !== step.path) {
        document.location.href = step.path;
        return;
      }
      e = this._initEvent({
        element: false
      });
      defs = [];
      if (step.onShow != null) {
        defs.push(this._deferred(step.onShow(this, e)));
      }
      if (this._options.onShow !== step.onShow) {
        defs.push(this._deferred(this._options.onShow(this, e)));
      }
      return $.when.apply($, defs).always(function() {
        var $el;
        $el = _this.getElement(step.element);
        e = _this._initEvent({
          element: $el
        });
        if (!((step.element != null) && $el.length !== 0 && $el.is(":visible"))) {
          _this.showNextStep(def);
          return;
        }
        _this._showPopover(step, i);
        if (step.onShown != null) {
          step.onShown(_this, e);
        }
        if (_this._options.onShown !== step.onShown) {
          _this._options.onShown(_this, e);
        }
        if (def) {
          return def.resolve();
        }
      });
    };

    Tour.prototype.setCurrentStep = function(value) {
      if (value != null) {
        this._current = value;
        return this.setState("current_step", value);
      } else {
        this._current = this.getState("current_step");
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
      options = $.extend({}, this._options);
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
      $nav = $(options.template(step)).wrapAll('<div/>').parent();
      if (step.prev === 0) {
        $nav.find('.prev').remove();
      }
      if (step.next === 0) {
        $nav.find('.next').remove();
      }
      content = $nav.html();
      $nav.remove();
      $el.popover({
        placement: step.placement,
        trigger: "manual",
        title: step.title,
        content: content,
        html: true,
        animation: step.animation
      });
      popover = $el.data("popover");
      tip = popover.tip().addClass("" + options.name + "-step" + i + " " + options.addClass + " " + step.addClass);
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
      var _this = this;
      if (this._options.keyboard) {
        return $(document).on("keyup.bootstrap-tour", function(e) {
          if (!e.which) {
            return;
          }
          switch (e.which) {
            case 39:
              e.preventDefault();
              if (_this._current < _this._steps.length - 1) {
                return _this.next();
              }
              break;
            case 37:
              e.preventDefault();
              if (_this._current > 0) {
                return _this.prev();
              }
          }
        });
      }
    };

    Tour.defaults = {
      name: "tour",
      persistence: "Memory",
      keyboard: true,
      addClass: "",
      template: function(step) {
        return '<p>#{step.content}</p>"\n<hr/>\n<p>\n  <a href="#{step.prev}" class="prev">Previous</a>\n  <a href="#{step.next}" class="next">Next</a>\n  <a href="#" class="pull-right end">End tour</a>\n</p>';
      },
      onShow: function(tour, event) {},
      onShown: function(tour, event) {},
      onHide: function(tour, event) {},
      afterSetState: function(key, value) {},
      afterGetState: function(key, value) {}
    };

    return Tour;

  })();
  return window.Tour = Tour;
})(jQuery, window);
