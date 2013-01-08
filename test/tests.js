var _when;

module("bootstrap-tour", {
  teardown: function() {
    return this.tour.dispose();
  }
});

/*
Execute sequentially the array of functions
@author FGRibreau
@param  {Array} arr Array of functions that return a promise
@param  {Object} ctx (optional)
@return {Deferred}
*/


_when = function(arr, ctx) {
  var def, next;
  next = function() {
    var fn;
    fn = arr.shift();
    if (!fn) {
      return def.resolve();
    }
    return fn.call(ctx).then(next);
  };
  def = $.Deferred();
  next();
  return def.promise();
};

test("Tour should set the tour options", function() {
  this.tour = new Tour({
    name: "test",
    afterSetState: function() {
      return true;
    },
    afterGetState: function() {
      return true;
    }
  });
  equal(this.tour._options.name, "test", "options.name is set");
  ok(this.tour._options.afterGetState, "options.afterGetState is set");
  return ok(this.tour._options.afterSetState, "options.afterSetState is set");
});

test("Tour should have default name of 'tour'", function() {
  this.tour = new Tour();
  return equal(this.tour._options.name, "tour", "tour default name is 'tour'");
});

test("Tour should accept an array of steps and set the current step", function() {
  this.tour = new Tour();
  deepEqual(this.tour._steps, [], "tour accepts an array of steps");
  return strictEqual(this.tour._current, 0, "tour initializes current step");
});

test("Tour.setState should save state cookie", function() {
  this.tour = new Tour({
    persistence: "Cookie"
  });
  this.tour._setState("test", "yes");
  return strictEqual($.cookie("tour_test"), "yes", "tour saves state");
});

test("Tour.getState should get state cookie", function() {
  this.tour = new Tour({
    persistence: "Cookie"
  });
  this.tour._setState("test", "yes");
  strictEqual(this.tour._getState("test"), "yes", "tour gets state");
  return $.cookie("tour_test", null);
});

test("Tour.setState should save state localstorage", function() {
  this.tour = new Tour({
    persistence: "LocalStorage"
  });
  this.tour._setState("test", "yes");
  return strictEqual(window.localStorage.getItem("tour_test"), "\"yes\"", "tour saves state");
});

test("Tour.getState should get state cookie with an null value if not found", function() {
  this.tour = new Tour({
    persistence: "Cookie"
  });
  return strictEqual(this.tour._getState("_heyhey_"), null, "null value if not found");
});

test("Tour.getState should get state localstorage with an null value if not found", function() {
  this.tour = new Tour({
    persistence: "LocalStorage"
  });
  return strictEqual(this.tour._getState("_heyhey_"), null, "null value if not found");
});

test("Tour.getState should get state memory with an null value if not found", function() {
  this.tour = new Tour({
    persistence: "Memory"
  });
  return strictEqual(this.tour._getState("_heyhey_"), null, "null value if not found");
});

test("Tour.getState should get state localstorage", function() {
  this.tour = new Tour({
    persistence: "LocalStorage"
  });
  this.tour._setState("test", "yes");
  strictEqual(this.tour._getState("test"), "yes", "tour saves state");
  return window.localStorage.setItem("tour_test", null);
});

test("Tour.setState should save state Memory", function() {
  this.tour = new Tour({
    persistence: "Memory"
  });
  this.tour._setState("test", "yes");
  return strictEqual(window["__db_tour__"]['test'], "yes", "tour saves state");
});

test("Tour.getState should get state Memory", function() {
  this.tour = new Tour({
    persistence: "Memory"
  });
  this.tour._setState("test", "yes");
  strictEqual(this.tour._getState("test"), "yes", "tour saves state");
  return window["__db_tour__"]['test'] = null;
});

test("Tour.addStep should add a step", function() {
  var step;
  this.tour = new Tour();
  step = {
    element: $("<div></div>").appendTo("#qunit-fixture")
  };
  this.tour.addStep(step);
  deepEqual(this.tour._steps[0].addClass, "", "tour adds steps");
  deepEqual(this.tour._steps[0].animation, true, "tour adds steps");
  deepEqual(this.tour._steps[0].element, step.element, "tour adds steps");
  deepEqual(this.tour._steps[0].placement, "right", "tour adds steps");
  deepEqual(this.tour._steps[0].reflex, false, "tour adds steps");
  deepEqual(this.tour._steps[0].title, "", "tour adds steps");
  return deepEqual(this.tour._steps[0].content, "", "tour adds steps");
});

test("Tour.addStep should support a function as `element`", function() {
  var step;
  this.tour = new Tour();
  $("<div id='ok'></div>").appendTo("#qunit-fixture");
  step = {
    element: function() {
      return $('#ok');
    }
  };
  this.tour.addStep(step);
  deepEqual(this.tour._steps[0].element, step.element, "tour adds steps");
  return this.tour.start();
});

test("Tour.addStep should support the addClass attribute", function() {
  var _class, _gclass;
  _gclass = 'testclass';
  _class = 'testclass';
  this.tour = new Tour({
    step: {
      addClass: _gclass
    }
  });
  this.tour.addStep({
    element: 'body',
    addClass: _class
  });
  this.tour.start();
  ok($('.popover').hasClass(_class), ".popover should now have the css class " + _class);
  return ok($('.popover').hasClass(_gclass), ".popover should now have the global css class " + _class);
});

test("._showPopover should automatically add a css class", function() {
  this.tour = new Tour({
    name: "ok"
  });
  this.tour.addStep({
    element: 'body'
  });
  this.tour.start();
  return ok($('.popover').hasClass("ok-step0"), "css class added");
});

test("Tour.getElement(step) handle string as well as function and return a jQuery wrapper", function() {
  var $el;
  this.tour = new Tour();
  $el = this.tour.getElement(function() {
    return $('body');
  });
  ok($el.is('body'));
  $el = this.tour.getElement(function() {
    return 'body';
  });
  ok($el.is('body'));
  $el = this.tour.getElement('body');
  ok($el.is('body'));
  $el = this.tour.getElement('notfound');
  ok($el.length === 0);
  return equal($el.is(':visible'), false);
});

test("Reflex event handlers should be cleaned after a step (via click)", function() {
  var step;
  expect(2);
  this.tour = new Tour();
  this.tour.on('hide', function(e) {
    return equal(e.trigger, "reflex", "the next() call was triggered by the reflex feature");
  });
  $("<a id='ok'>hey</a>").appendTo("#qunit-fixture");
  step = {
    element: '#ok',
    reflex: true
  };
  this.tour.addStep(step);
  this.tour.next = function(e) {
    this.hideStep(this._current, e);
    return equal(true, true, "should only be called on time");
  };
  this.tour.start();
  return $("#ok").trigger('click').trigger('click');
});

test("Reflex event handlers should be cleaned after a step (via API)", function() {
  var step;
  expect(1);
  this.tour = new Tour();
  $("<a id='ok'>hey</a>").appendTo("#qunit-fixture");
  step = {
    element: '#ok',
    reflex: true
  };
  this.tour.addStep(step);
  this.tour.next = function() {
    this.hideStep(this._current);
    return equal(true, true, "should be called one time");
  };
  this.tour.start();
  this.tour.next();
  return $("#ok").trigger('click');
});

test("Tour with onShow option should run the callback before showing the step", function() {
  var tour_test;
  tour_test = 0;
  this.tour = new Tour({});
  this.tour.on('show', function(e) {
    return tour_test += 2;
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  strictEqual(tour_test, 2, "tour runs onShow when first step shown");
  return $.when(this.tour.next(), function() {
    return strictEqual(tour_test, 4, "tour runs onShow when next step shown");
  });
});

test("Tour with onShow option should wait on the promise callback", function() {
  var resolved;
  this.tour = new Tour();
  resolved = false;
  this.tour.addStep({
    element: function() {
      QUnit.start();
      if (!resolved) {
        ok(false, "element should be called only after onShow has completed");
      }
      return ok(true);
    }
  });
  this.tour.on('show:step0', function(e) {
    var def;
    def = $.Deferred();
    setTimeout(function() {
      resolved = true;
      return def.resolve();
    }, 100);
    return e.setPromise(def.promise());
  });
  QUnit.stop();
  return this.tour.start();
});

test("onShow(..., event) should not contain element attr, but onShown(..., event) should", function() {
  var $div;
  expect(2);
  this.tour = new Tour();
  $div = $("<div></div>").appendTo("#qunit-fixture");
  this.tour.addStep({
    element: function() {
      return $div;
    }
  });
  this.tour.on('show', function(e) {
    QUnit.start();
    strictEqual(e.element, void 0, "element should not be specified");
    return QUnit.stop();
  });
  this.tour.on('shown', function(e) {
    QUnit.start();
    return ok(e.element.is($div));
  });
  QUnit.stop();
  return this.tour.start();
});

test("Tour with onShown option should run the callback after showing the step", function() {
  var tour_test;
  tour_test = 0;
  this.tour = new Tour();
  this.tour.on('shown', function(e) {
    return tour_test += 2;
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  return strictEqual(tour_test, 2, "tour runs onShown after first step shown");
});

test("Tour with onHide option should run the callback before hiding the step", function() {
  var $el1, $el2, tour_test,
    _this = this;
  expect(6);
  tour_test = 0;
  $el1 = $("<div></div>").appendTo("#qunit-fixture");
  $el2 = $("<div></div>").appendTo("#qunit-fixture");
  this.tour = new Tour();
  this.tour.on('hide', function(e) {
    equal(e.trigger, "api");
    ok(e.element.is($el1) || e.element.is($el2), "e.element should be specified");
    return tour_test += 2;
  });
  this.tour.addStep({
    element: $el1
  });
  this.tour.addStep({
    element: $el2
  });
  this.tour.start();
  return this.tour.next().always(function() {
    strictEqual(tour_test, 2, "tour runs onHide when first step hidden");
    _this.tour.hideStep(1);
    return strictEqual(tour_test, 4, "tour runs onHide when next step hidden");
  });
});

test("Tour with onHide/onShow option should not be overriden by the step onHide/onShow level option", function() {
  expect(6);
  this.tour = new Tour();
  this.tour.on('hide', function(e) {
    return ok(true, "onHide tour level called");
  });
  this.tour.on('show', function(e) {
    return ok(true, "onShow tour level called");
  });
  this.tour.on('shown', function(e) {
    return ok(true, "onShown tour level called");
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.on('hide:step0', function(e) {
    return ok(true, "onHide step level called");
  });
  this.tour.on('show:step0', function(e) {
    return ok(true, "onShow step level called");
  });
  this.tour.on('shown:step0', function(e) {
    return ok(true, "onShown step level called");
  });
  this.tour.start();
  return this.tour.next();
});

test("Tour.addStep with onShow option should run the callback before showing the step", function() {
  var tour_test;
  tour_test = 0;
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.on('show:step1', function(e) {
    return tour_test = 2;
  });
  this.tour.start();
  strictEqual(tour_test, 0, "tour does not run onShow when step not shown");
  return $.when(this.tour.next(), function() {
    return strictEqual(tour_test, 2, "tour runs onShow when step shown");
  });
});

test("Tour.addStep with onHide option should run the callback before hiding the step", function() {
  var tour_test;
  tour_test = 0;
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.on('hide:step1', function(e) {
    return tour_test = 2;
  });
  this.tour.start();
  this.tour.next();
  strictEqual(tour_test, 0, "tour does not run onHide when step not hidden");
  this.tour.hideStep(1);
  return strictEqual(tour_test, 2, "tour runs onHide when step hidden");
});

test("Tour.getStep should get a step", function() {
  var step;
  this.tour = new Tour();
  step = {
    element: $("<div></div>").appendTo("#qunit-fixture"),
    path: "test",
    placement: "left",
    title: "Test",
    content: "Just a test",
    addClass: "",
    prev: -1,
    index: 0,
    reflex: false,
    next: 2,
    end: false,
    animation: false
  };
  this.tour.addStep(step);
  return deepEqual(this.tour.getStep(0), step, "tour gets a step");
});

test("Tour.start should start a tour", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  return strictEqual($(".popover").length, 1, "tour starts");
});

test("Tour.start should not start a tour that ended", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour._setState("end", "yes");
  this.tour.start();
  return strictEqual($(".popover").length, 0, "previously ended tour don't start again");
});

test("Tour.start(true) should force starting a tour that ended", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour._setState("end", "yes");
  this.tour.start(true);
  return strictEqual($(".popover").length, 1, "previously ended tour starts again if forced to");
});

test("Tour.next should hide current step and show next step", function() {
  var _this = this;
  expect(2);
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div class='ok'></div>").appendTo("#qunit-fixture")
  });
  QUnit.stop();
  return _when([this.tour.start, this.tour.next], this.tour).then(function() {
    QUnit.start();
    strictEqual(_this.tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step");
    return strictEqual(_this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step");
  });
});

test("Tour.next should return a promise", function() {
  var _this = this;
  expect(1);
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.on('show:step0', function(e) {
    var def;
    def = $.Deferred();
    setTimeout(def.resolve, 10);
    return e.setPromise(def.promise());
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  QUnit.stop();
  return _when([this.tour.start, this.tour.next], this.tour).then(function() {
    QUnit.start();
    return ok(true, "executed");
  });
});

test("Tour.prev should return a promise", function() {
  expect(1);
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.on('show:step0', function(e) {
    var def;
    def = $.Deferred();
    setTimeout(def.resolve, 10);
    return e.setPromise(def.promise());
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  this.tour.next();
  QUnit.stop();
  return this.tour.prev().then(function() {
    QUnit.start();
    return ok(true, "executed");
  });
});

test("Tour.end should hide current step and set end state", function() {
  expect(6);
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  this.tour.on("end", function(e) {
    equal(e.step.index, 0);
    return equal(e.trigger, "api");
  });
  this.tour.on("end:step0", function(e) {
    equal(e.step.index, 0);
    return equal(e.trigger, "api");
  });
  this.tour.end();
  strictEqual(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step");
  return strictEqual(this.tour._getState("end"), "yes", "tour sets end state");
});

test("Tour.ended should return true is tour ended and false if not", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  strictEqual(this.tour.ended(), false, "tour returns false if not ended");
  this.tour.end();
  return strictEqual(this.tour.ended(), true, "tour returns true if ended");
});

test("Tour.restart should clear all states and start tour", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  this.tour.next();
  this.tour.end();
  this.tour.restart();
  strictEqual(this.tour._getState("end"), null, "tour sets end state");
  strictEqual(this.tour._current, 0, "tour sets first step");
  return strictEqual($(".popover").length, 1, "tour starts");
});

test("Tour.hideStep should hide a step", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  this.tour.hideStep(0);
  return strictEqual(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides step");
});

test("Tour.showStep should set a step and show it", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(1);
  strictEqual(this.tour._current, 1, "tour sets step");
  strictEqual($(".popover").length, 1, "tour shows one step");
  return strictEqual(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows correct step");
});

test("Tour.showStep should not show anything when the step doesn't exist", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(2);
  return strictEqual($(".popover").length, 0, "tour doesn't show any step");
});

test("Tour.showStep should skip step when no element is specified", function() {
  this.tour = new Tour();
  this.tour.addStep({});
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(1);
  return strictEqual(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element");
});

test("Tour.showStep should skip step when element doesn't exist", function() {
  expect(3);
  this.tour = new Tour();
  this.tour.one('skipping', function(e) {
    equal(e.type, "skipping");
    return deepEqual(e.step.index, 0);
  });
  this.tour.addStep({
    element: "#tour-test"
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(0);
  return strictEqual(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element");
});

test("Tour.showStep should skip step when element is invisible", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div class='hidden-div'></div>").appendTo("#qunit-fixture").hide()
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(1);
  return strictEqual(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element");
});

test("Tour.setCurrentStep should set the current step", function() {
  this.tour = new Tour();
  this.tour.setCurrentStep(4);
  strictEqual(this.tour._current, 4, "tour sets current step if passed a value");
  this.tour._setState("current_step", 2);
  this.tour.setCurrentStep();
  return strictEqual(this.tour._current, 2, "tour reads current step state if not passed a value");
});

test("Tour.showNextStep should show the next step", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  this.tour.showNextStep();
  return strictEqual(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step");
});

test("Tour.showPrevStep should show the previous step", function() {
  this.tour = new Tour();
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  });
  this.tour.showStep(1);
  this.tour.showPrevStep();
  return strictEqual(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length, 1, "tour shows previous step");
});

test(".initEvent with an element", function() {
  var $div, e;
  expect(1);
  this.tour = new Tour();
  $div = $("<div></div>").appendTo("#qunit-fixture");
  e = this.tour._initEvent("plop", {
    element: $div
  });
  return deepEqual(e.element, $div);
});

/**
 * Overlay
*/


test("Should add the div/css for overlay if it was set to true", function() {
  expect(2);
  this.tour = new Tour({
    step: {
      overlay: true
    }
  });
  this.tour.addStep({
    element: $("<div id='a'></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  equal($('#bootstrap-tour-style').length, 1);
  this.tour.dispose();
  return equal($('#bootstrap-tour-style').length, 0);
});

test("Should not add the div/css for overlay if it was set to false", function() {
  expect(1);
  this.tour = new Tour({
    step: {
      overlay: false
    }
  });
  return equal($('#bootstrap-tour-style').length, 0);
});

test("Should display an overlay for the element if it was set to true", function() {
  expect(2);
  this.tour = new Tour({
    step: {
      overlay: true
    }
  });
  this.tour.addStep({
    element: $("<div id='a'></div>").appendTo("#qunit-fixture")
  });
  this.tour.addStep({
    element: $("<div id='b'></div>").appendTo("#qunit-fixture")
  });
  this.tour.start();
  ok($('#a').hasClass('bootstrap-tour-expose'), "should have an expose class");
  return ok($('#bootstrap-tour-overlay').is(':visible'), "overlay should be visible");
});
