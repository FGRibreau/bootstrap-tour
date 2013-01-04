# Bootstrap Tour [![Build Status](https://travis-ci.org/FGRibreau/bootstrap-tour.png)](https://travis-ci.org/FGRibreau/bootstrap-tour)

Quick and easy product tours with Twitter Bootstrap Popovers.

Fork of [sorich87 bootstrap-tour](http://sorich87.github.com/bootstrap-tour/).

Extra features
------------
- [Improvement] `Tour` constructor now accept a `template` attribute thus the `labels.*` attribute has been removed.
- [Improvement] If `onShow` (at the `step` level or `Tour` level) returns a promise (see [$.Deferred()](http://api.jquery.com/category/deferred-object/)), Bootstrap-tour will wait until the completition of the promise(s) before displaying the popover
- [Improvement] Persistence option `Memory`, `Cookie`, `LocalStorage` via constructor `new Tour({persistence:"LocalStorage"})`
- [Improvement] `onHide` and `onShow` callbacks now have a second argument `Event` with
  - `{String}` `Event.trigger`:: `api | popover | reflex`
  - `{jQuery}` `Event.element`: the current step element
- [Improvement] `addStep` now accept a function as `element`
- [Improvement] `addStep` and `Tour` constructor now accept `addClass` string attribute, the specified css class will then be added to the popover element
- [Improvement] the popover element now have an automatically added `{tour.name}-step{step.index}` css class
- [Bug fix] Don't create unnecessary $() objects
- [Bug fix] Remove event handlers after each step when `reflex:true`
- [Bug fix] `onHide`, `onShow`, `onShown` callbacks at the step level should not override `onHide`, `onShow`, `onShown` at the tour level

## Getting Started
In your web page:

```html
<script src="jquery.js"></script>
<script src="jquery.cookie.js"></script>
<script src="bootstrap.tooltip.js"></script>
<script src="bootstrap.popover.js"></script>
<script src="bootstrap-tour.min.js"></script>

<script type="text/javascript">
// Initialize the tour
var tour = new Tour({
  name:"myTour"
});

//  Add steps
tour.addStep({
  element: "", /* html element (or function) next to which the step popover should be shown */
  title: "", /* title of the popover */
  content: "" /* content of the popover */
});

// Start the tour
tour.start();
</script>
```

## Documentation
For the Tour instance API see [the original documentation](http://sorich87.github.com/bootstrap-tour/)

### Tour Constructor
The `Tour` constructor accept an option object with the following optional attributes:

```coffeescript
#
# {String} The tour name
#
name: 'tour'

#
# {String} "Cookie" | "LocalStorage" | "Memory" (default "Cookie")
#
persistence: 'Cookie'

#
# {Boolean} Keyboard navigation
#
keyboard: true

#
# {String} Css class to add to the .popover element
#
addClass:""

#
# {Function} Navigation template, `.prev`, `.next` and `.end`
# will be removed at runtime if necessary
#
# The template can be an underscore template or $.tmpl ...
#
template:(step) ->
  '''
    <p>#{step.content}</p>"
    <hr/>
    <p>
      <a href="#{step.prev}" class="prev">Previous</a>
      <a href="#{step.next}" class="next">Next</a>
      <a href="#" class="pull-right end">End tour</a>
    </p>
  '''

#
# {Function} Called before showing a popover
# If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
# completition of the promise before displaying the popover
#
onShow: (tour, event) ->

#
# {Function} Called after a popover is shown
#
onShown: (tour, event) ->

#
# {Function Called when a popover is hidden
#
onHide: (tour, event) ->

afterSetState: (key, value) ->
afterGetState: (key, value) ->
```

### `.addStep(options)` options object

```coffeescript
#
# {String} Path to the page on which the step should be shown. this allows you
# to build tours that span several pages!
#
path: ""

#
# {jQuery | Css Selector | Function} HTML element on which the step popover
# should be shown.
#
element:null

#
# {String} How to position the popover - top | bottom | left | right.
#
placement: "right"

#
# {String} Step title
#
title: ""

#
# {String} Step content
#
content: ""

#
# {Number} Index of the step to show after this one, starting from 0 for the
# first step of the tour. -1 to not show the link to next step.
# By default, the next step (in the order you added them) will be shown.
#
next: if i == @_steps.length - 1 then -1 else i + 1

#
# {Number} Index of the step to show before this one, starting from 0 for
# the first step of the tour. -1 to not show the link to previous step.
# By default, the previous step (in the order you added them) will be shown.
#
prev: i - 1

#
# {Boolean} Apply a css fade transition to the tooltip.
#
animation: true

#
# {Boolean} Enable the reflex mode, click on the element to continue the tour
#
reflex: false

#
# {String} Css class to add to the .popover element for this step only
#
addClass:""

#
# {Function} Function to execute right before each step is shown.
# If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
# completition of the promise before displaying the popover
#
onShow: $.noop

#
# {Function} Function to execute right after each step is shown.
#
onShown: $.noop

#
# {Function} Function to execute right before each step is hidden.
#
onHide: $.noop
```

## NPM
Install with `npm install bootstrap-tour`

## Release History
v0.1.0 - Initial commit

## License
Copyright (c) 2013 FG Ribreau
Licensed under the MIT, GPL licenses.

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [grunt](https://github.com/cowboy/grunt).

### Important notes
Please don't edit files in the `dist` subdirectory as they are generated via grunt. You'll find source code in the `src` subdirectory!

While grunt can run the included unit tests via PhantomJS, this shouldn't be considered a substitute for the real thing. Please be sure to test the `test/*.html` unit test file(s) in _actual_ browsers.
