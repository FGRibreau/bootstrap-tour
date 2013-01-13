module("bootstrap-tour",
  teardown: ->
    @tour.dispose() if @tour
)


###
Execute sequentially the array of functions
@author FGRibreau
@param  {Array} arr Array of functions that return a promise
@param  {Object} ctx (optional)
@return {Deferred}
###
_when = (arr, ctx) ->
  next = ->
    fn = arr.shift()
    return def.resolve()  unless fn
    fn.call(ctx).then next
  def = $.Deferred()
  next()
  def.promise()


test "Tour should set the tour options", ->
  @tour = new Tour({
    name: "test"
    afterSetState: ->
      true
    afterGetState: ->
      true
  })
  equal(@tour._options.name, "test", "options.name is set")
  ok(@tour._options.afterGetState, "options.afterGetState is set")
  ok(@tour._options.afterSetState, "options.afterSetState is set")

test "Tour should have default name of 'tour'", ->
  @tour = new Tour()
  equal(@tour._options.name, "tour", "tour default name is 'tour'")

test "Tour should accept an array of steps and set the current step", ->
  @tour = new Tour()
  deepEqual(@tour._steps, [], "tour accepts an array of steps")
  strictEqual(@tour._current, 0, "tour initializes current step")

test "Tour.setState should save state cookie", ->
  @tour = new Tour(persistence:"Cookie")
  @tour._setState("test", "yes")
  strictEqual($.cookie("tour_test"), "yes", "tour saves state")

test "Tour.getState should get state cookie", ->
  @tour = new Tour(persistence:"Cookie")
  @tour._setState("test", "yes")
  strictEqual(@tour._getState("test"), "yes", "tour gets state")
  $.cookie("tour_test", null)

test "Tour.setState should save state localstorage", ->
  @tour = new Tour(persistence:"LocalStorage")
  @tour._setState("test", "yes")
  strictEqual(window.localStorage.getItem("tour_test"), "\"yes\"", "tour saves state")

test "Tour.getState should get state cookie with an null value if not found", ->
  @tour = new Tour(persistence:"Cookie")
  strictEqual(@tour._getState("_heyhey_"), null, "null value if not found")

test "Tour.getState should get state localstorage with an null value if not found", ->
  @tour = new Tour(persistence:"LocalStorage")
  strictEqual(@tour._getState("_heyhey_"), null, "null value if not found")

test "Tour.getState should get state memory with an null value if not found", ->
  @tour = new Tour(persistence:"Memory")
  strictEqual(@tour._getState("_heyhey_"), null, "null value if not found")

test "Tour.getState should get state localstorage", ->
  @tour = new Tour(persistence:"LocalStorage")
  @tour._setState("test", "yes")
  strictEqual(@tour._getState("test"), "yes", "tour saves state")
  window.localStorage.setItem("tour_test", null)

test "Tour.setState should save state Memory", ->
  @tour = new Tour(persistence:"Memory")
  @tour._setState("test", "yes")
  strictEqual(window["__db_tour__"]['test'], "yes", "tour saves state")

test "Tour.getState should get state Memory", ->
  @tour = new Tour(persistence:"Memory")
  @tour._setState("test", "yes")
  strictEqual(@tour._getState("test"), "yes", "tour saves state")
  window["__db_tour__"]['test'] = null;

test "Tour.addStep should add a step", ->
  @tour = new Tour()
  step = { element: $("<div></div>").appendTo("#qunit-fixture") }
  @tour.addStep(step)
  deepEqual(@tour._steps[0].addClass, "", "tour adds steps")
  deepEqual(@tour._steps[0].animation, true, "tour adds steps")
  deepEqual(@tour._steps[0].element, step.element, "tour adds steps")
  deepEqual(@tour._steps[0].placement, "right", "tour adds steps")
  deepEqual(@tour._steps[0].reflex, false, "tour adds steps")
  deepEqual(@tour._steps[0].title, "", "tour adds steps")
  deepEqual(@tour._steps[0].content, "", "tour adds steps")

test "Tour.addStep should support a function as `element`", ->
  @tour = new Tour()
  $("<div id='ok'></div>").appendTo("#qunit-fixture")

  step = { element: ()-> $('#ok'); }
  @tour.addStep(step)
  deepEqual(@tour._steps[0].element, step.element, "tour adds steps")
  @tour.start()

test "Tour.addStep should support the addClass attribute", ->
  _gclass = 'testclass'
  _class = 'testclass'

  @tour = new Tour({
    step:
      addClass: _gclass
  })
  @tour.addStep({
    element: 'body'
    addClass: _class
  })

  @tour.start()
  ok($('.popover').hasClass(_class), ".popover should now have the css class #{_class}")
  ok($('.popover').hasClass(_gclass), ".popover should now have the global css class #{_class}")

test "._showPopover should automatically add a css class", ->
  @tour = new Tour(name:"ok")
  @tour.addStep(element: 'body')
  @tour.start()
  ok($('.popover').hasClass("ok-step0"), "css class added")


test "Tour._getElement(step) handle string as well as function and return a jQuery wrapper", ->
  @tour = new Tour()

  $el = @tour._getElement(() -> $('body'))
  ok($el.is('body'))

  $el = @tour._getElement(() -> 'body')
  ok($el.is('body'))

  $el = @tour._getElement('body')
  ok($el.is('body'))

  $el = @tour._getElement('notfound')
  ok($el.length is 0)
  equal($el.is(':visible'), false)


test "Reflex event handlers should be cleaned after a step (via click)", ->
  expect(2)

  @tour = new Tour()

  @tour.on('hide', (e) ->
    equal(e.trigger, "reflex", "the next() call was triggered by the reflex feature")
  )

  $("<a id='ok'>hey</a>").appendTo("#qunit-fixture");
  step =
    element: '#ok'
    reflex: true
  @tour.addStep(step)

  @tour.next = (e) ->
    @_hideStep(@_current, e)
    equal(true, true, "should only be called on time")

  @tour.start()
  $("#ok").trigger('click').trigger('click')

test "Reflex event handlers should be cleaned after a step (via API)", ->
  expect(1)

  @tour = new Tour()
  $("<a id='ok'>hey</a>").appendTo("#qunit-fixture");
  step =
    element: '#ok'
    reflex:true
  @tour.addStep(step)

  @tour.next = () ->
    @_hideStep(@_current)
    equal(true, true, "should be called one time")

  @tour.start()
  @tour.next()
  $("#ok").trigger('click')


test "Tour with onShow option should run the callback before showing the step", ->
  tour_test = 0
  @tour = new Tour({
  })
  @tour.on('show', (e) ->tour_test += 2)
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(tour_test, 2, "tour runs onShow when first step shown")

  $.when(@tour.next(), () ->
    strictEqual(tour_test, 4, "tour runs onShow when next step shown")
  )


test "Tour with onShow option should wait on the promise callback", ->
  @tour    = new Tour()
  resolved = false

  @tour.addStep({
    element: () ->
      QUnit.start()
      if !resolved
        ok(false, "element should be called only after onShow has completed")
      ok(true)
  })

  @tour.on('show:step0', (e) ->
    def = $.Deferred()
    setTimeout(() ->
      resolved = true
      def.resolve()
    , 100)
    e.setPromise(def.promise())
  )

  QUnit.stop()
  @tour.start()

test "onShow(..., event) should not contain element attr, but onShown(..., event) should", ->
  expect(2)
  @tour = new Tour()
  $div = $("<div></div>").appendTo("#qunit-fixture")
  @tour.addStep(element: () -> $div)
  @tour.on('show', (e) ->
    QUnit.start()
    strictEqual(e.element, undefined, "element should not be specified")
    QUnit.stop()
  )
  @tour.on('shown', (e) ->
    QUnit.start()
    ok(e.element.is($div))
    )
  QUnit.stop()
  @tour.start()

test "Tour with onShown option should run the callback after showing the step", ->
  tour_test = 0
  @tour = new Tour()
  @tour.on('shown', (e) -> tour_test += 2)
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(tour_test, 2, "tour runs onShown after first step shown")

test "Tour with onHide option should run the callback before hiding the step", ->
  expect(6)

  tour_test = 0
  $el1 = $("<div></div>").appendTo("#qunit-fixture")
  $el2 = $("<div></div>").appendTo("#qunit-fixture")
  @tour = new Tour()
  @tour.on('hide', (e) ->
    equal(e.trigger, "api")
    ok(e.element.is($el1) || e.element.is($el2), "e.element should be specified")
    tour_test += 2
  )
  @tour.addStep({element: $el1})
  @tour.addStep({element: $el2})
  @tour.start()
  @tour.next().always(() =>
    strictEqual(tour_test, 2, "tour runs onHide when first step hidden")
    @tour._hideStep(1)
    strictEqual(tour_test, 4, "tour runs onHide when next step hidden")
  )

test "Tour with onHide/onShow option should not be overriden by the step onHide/onShow level option", ->
  expect(6);

  @tour = new Tour()
  @tour.on('hide', (e) -> ok(true, "onHide tour level called"))
  @tour.on('show', (e) -> ok(true, "onShow tour level called"))
  @tour.on('shown', (e) -> ok(true, "onShown tour level called"))

  @tour.addStep(
    element: $("<div></div>").appendTo("#qunit-fixture")
  )
  @tour.on('hide:step0', (e) -> ok(true, "onHide step level called"))
  @tour.on('show:step0', (e) -> ok(true, "onShow step level called"))
  @tour.on('shown:step0', (e) -> ok(true, "onShown step level called"))

  @tour.start()
  @tour.next()

test "Tour.addStep with onShow option should run the callback before showing the step", ->
  tour_test = 0
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  })
  @tour.on('show:step1', (e) -> tour_test = 2)
  @tour.start()
  strictEqual(tour_test, 0, "tour does not run onShow when step not shown")
  $.when(@tour.next(), () ->
    strictEqual(tour_test, 2, "tour runs onShow when step shown")
  )

test "Tour.addStep with onHide option should run the callback before hiding the step", ->
  expect(1);
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  })
  @tour.on('hide:step0', (e) ->
    QUnit.start()
    ok(true, "tour runs onHide when step hidden")
  )
  QUnit.stop()
  @tour.start()
  @tour.next()

test "Tour.addStep", ->
  expect(2)
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  equal(@tour._getStep(0).index, 0)
  equal(@tour._getStep(1).index, 1)

test "Tour.addStep with onHide option should wait (if necessary) for `hide` deferred to resolve before hiding the step", ->
  expect(2);

  resolved = false
  @tour    = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.on('hide:step0', (e) ->
    def = $.Deferred()
    setTimeout(() =>
      resolved = true
      def.resolve()
    , 100)
    e.setPromise(def.promise())
  )
  # QUnit.stop()
  @tour.on('show:step1', (e) ->
    QUnit.start()
    ok(resolved, "the hide deferred should be resolved before show:step1 is triggered")
  )
  @tour.start().always(() =>
    QUnit.start()
    equal(@tour._current, 0)
    QUnit.stop()
    @tour.next()
  )

test "Tour._getStep should get a step", ->
  @tour = new Tour()
  step = {
    element: $("<div></div>").appendTo("#qunit-fixture")
    path: "test"
    placement: "left"
    title: "Test"
    content: "Just a test"
    addClass: ""
    prev: -1
    index: 0
    reflex:false
    next: -1
    end: false
    animation: false
  }
  @tour.addStep(step)
  deepEqual(@tour._getStep(0), step, "tour gets a step")

test "Tour.start should start a tour", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual($(".popover").length, 1, "tour starts")

test "Tour.start should not start a tour that ended", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._setState("end", "yes")
  @tour.start()
  strictEqual($(".popover").length, 0, "previously ended tour don't start again")

test "Tour.start(true) should force starting a tour that ended", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._setState("end", "yes")
  @tour.start(true)
  strictEqual($(".popover").length, 1, "previously ended tour starts again if forced to")

test "Tour should not go to the next step if .next is disabled", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  equal(@tour._current, 0, "current step should be 0")
  $('.popover .next').attr('disabled', 'disabled').trigger('click')
  equal(@tour._current, 0, "current step should still be 0")

test "Tour should not go to the next step if .prev is disabled", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  equal(@tour._current, 1, "current step should be 1")
  $('.popover .prev').attr('disabled', 'disabled').trigger('click')
  equal(@tour._current, 1, "current step should still be 1")

test "Tour should not end the tour if .end is disabled", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  equal(@tour.ended(), false, "tour should not be ended")
  $('.popover .end').attr('disabled', 'disabled').trigger('click')
  equal(@tour.ended(), false, "tour should not be ended")

test "Tour.next should hide current step and show next step", ->
  expect(2)
  @tour = new Tour()
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  })
  @tour.addStep({
    element: $("<div class='ok'></div>").appendTo("#qunit-fixture")
  })

  QUnit.stop();
  _when([@tour.start, @tour.next], @tour).then(() =>
    QUnit.start();
    strictEqual(@tour._getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step")
    strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step")
  )

test "Tour.next should return a promise", ->
  expect(1)
  @tour = new Tour()
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  })

  @tour.on('show:step0', (e) ->
    def = $.Deferred()
    setTimeout(def.resolve, 10)
    e.setPromise(def.promise())
  )
  # deepEqual(@tour._options.step.onHide(), undefined)
  # deepEqual(Tour.defaults.step.onHide(), undefined)
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  QUnit.stop()
  _when([@tour.start, @tour.next], @tour).then(() =>
    QUnit.start()
    ok(true, "executed")
  )

test "Tour.prev should return a promise", ->
  expect(1)
  @tour = new Tour()
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
  })
  @tour.on('show:step0', (e) ->
    def = $.Deferred()
    setTimeout(def.resolve, 10)
    e.setPromise(def.promise())
  )
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  QUnit.stop()
  @tour.prev().then(() ->
    QUnit.start()
    ok(true, "executed")
  )

test "Tour.end should hide current step and set end state", ->
  expect(6)
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.on("end", (e) ->
    equal(e.step.index, 0);
    equal(e.trigger, "api");
  )
  @tour.on("end:step0", (e) ->
    equal(e.step.index, 0);
    equal(e.trigger, "api");
  )
  @tour.end()
  strictEqual(@tour._getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step")
  strictEqual(@tour._getState("end"), "yes", "tour sets end state")

test "Tour.ended should return true is tour ended and false if not", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(@tour.ended(), false, "tour returns false if not ended")
  @tour.end()
  strictEqual(@tour.ended(), true, "tour returns true if ended")

test "Tour.restart should clear all states and start tour", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  @tour.end()
  @tour.restart()
  strictEqual(@tour._getState("end"), null, "tour sets end state")
  strictEqual(@tour._current, 0, "tour sets first step")
  strictEqual($(".popover").length, 1, "tour starts")

test "Tour._hideStep should hide a step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour._hideStep(0)
  strictEqual(@tour._getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides step")

test "Tour._showStep should set a step and show it", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(1)
  strictEqual(@tour._current, 1, "tour sets step")
  strictEqual($(".popover").length, 1, "tour shows one step")
  strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows correct step")

test "Tour._showStep should not show anything when the step doesn't exist", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(2)
  strictEqual($(".popover").length, 0, "tour doesn't show any step")

test "Tour._showStep should skip step when no element is specified", ->
  @tour = new Tour()
  @tour.addStep({})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(1)
  strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour._showStep should skip step when element doesn't exist", ->
  expect(3)
  @tour = new Tour()
  @tour.one('skip', (e) ->
    equal(e.type, "skip")
    deepEqual(e.step.index, 0)
  )
  @tour.addStep({element: "#tour-test"})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(0)
  strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour._showStep should skip step when element is invisible", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div class='hidden-div'></div>").appendTo("#qunit-fixture").hide()})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(1)
  strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour.setCurrentStep should set the current step", ->
  @tour = new Tour()
  @tour._setCurrentStep(4)
  strictEqual(@tour._current, 4, "tour sets current step if passed a value")
  @tour._setState("current_step", 2)
  @tour._initCurrentStep()
  strictEqual(@tour._current, 2, "tour reads current step state if not passed a value")

test "Tour._showNextStep should show the next step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour._showNextStep()
  strictEqual(@tour._getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step")

test "Tour._showPrevStep should show the previous step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour._showStep(1)
  @tour._showPrevStep()
  strictEqual(@tour._getStep(0).element.data("popover").tip().filter(":visible").length, 1, "tour shows previous step")

test ".initEvent with an element", ->
  expect(1)
  @tour = new Tour()
  $div = $("<div></div>").appendTo("#qunit-fixture")
  e = @tour._initEvent("plop", element:$div)
  deepEqual(e.element, $div)

###*
 * Overlay
###
test "Should add the div/css for overlay if it was set to true", ->
  expect(2)
  @tour = new Tour(
    step:
      overlay:true
  )
  @tour.addStep({element: $("<div id='a'></div>").appendTo("#qunit-fixture")})
  @tour.start();

  equal($('#bootstrap-tour-style').length, 1)
  @tour.dispose()
  equal($('#bootstrap-tour-style').length, 0)


test "Should not add the div/css for overlay if it was set to false", ->
  expect(1)
  @tour = new Tour(
    step:
      overlay:false)
  equal($('#bootstrap-tour-style').length, 0)

test "Should display an overlay for the element if it was set to true", ->
  expect(2)
  @tour = new Tour(
    step:
      overlay:true)
  @tour.addStep({element: $("<div id='a'></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div id='b'></div>").appendTo("#qunit-fixture")})
  @tour.start()
  ok($('#a').hasClass('bootstrap-tour-expose'), "should have an expose class")
  ok($('#bootstrap-tour-overlay').is(':visible'), "overlay should be visible")

###*
 * Private API
###
test "_getProp handle null obj", ->
  expect(2)
  deepEqual(new Tour()._getProp(null, {}, "template"), null)
  deepEqual(new Tour()._getProp({}, null, "template"), null)

test "_getProp should select the right value", ->
  expect(4)
  @tour = new Tour()
  a = {template:false}
  b = {}
  deepEqual(@tour._getProp(a, b, "template"), false)
  deepEqual(@tour._getProp(b, a, "template"), false)
  a = {template:true}
  b = {}
  deepEqual(@tour._getProp(a, b, "template"), true)
  deepEqual(@tour._getProp(b, a, "template"), true)

test "_getProp should select the right function", ->
  expect(4)
  @tour = new Tour()
  a = {template:() -> false}
  b = {}
  deepEqual(@tour._getProp(a, b, "template"), false)
  deepEqual(@tour._getProp(b, a, "template"), false)
  a = {template:() -> true}
  b = {}
  deepEqual(@tour._getProp(a, b, "template"), true)
  deepEqual(@tour._getProp(b, a, "template"), true)
