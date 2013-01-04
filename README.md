# Bootstrap Tour [![Build Status](https://travis-ci.org/FGRibreau/bootstrap-tour.png)](https://travis-ci.org/FGRibreau/bootstrap-tour)

Quick and easy product tours with Twitter Bootstrap Popovers.

Fork of [sorich87 bootstrap-tour](http://sorich87.github.com/bootstrap-tour/).

Extra features
------------
- [Improvement] `Tour` constructor now accept a `template` attribute thus the `labels.*` attribute has been removed.
- [Improvement] Persistence option `Memory`, `Cookie`, `LocalStorage` via constructor `new Tour({persistence:"LocalStorage"})`
- [Improvement] `onHide` and `onShow` callbacks now have a second argument `Event` with
  - `{String}` `Event.trigger`:: `api | popover | reflex`
  - `{jQuery}` `Event.element`: the current step element
- [Improvement] `addStep` now accept a function as `element`
- [Improvement] `addStep` and `Tour` constructor now accept `addClass` string attribute, the specified css class will then be added to the popover element
- [Improvement] the popover element now have an automatically added `{tour.name}-step{step.index}` css class
- [Improvement] `Tour` constructor now accept a `hidePrev` flag, if set to true, the `prev` button will always be hidden.
- [Bug fix] Don't create unnecessary $() objects
- [Bug fix] Remove event handlers after each step when `reflex:true`
- [Bug fix] `onHide`, `onShow`, `onShown` callbacks at the step level should not override `onHide`, `onShow`, `onShown` at the tour level

## Getting Started
Download the [production version][min] or the [development version][max].
Or install with `npm install bootstrap-tour`

[min]: https://raw.github.com/FGRibreau/bootstrap-tour/master/dist/bootstrap-tour.min.js
[max]: https://raw.github.com/FGRibreau/bootstrap-tour/master/dist/bootstrap-tour.js

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
# {Boolean} True if the previous button should always be hidden
#
hidePrev: false

#
# {String} Css class to add to the .popover element
#
addClass:""

#
# {Function} Navigation template, `.prev`, `.next` and `.end`
# will be removed at runtime if necessary
# @param {Object} Input object that contains a `step` attribute as the current step
template:(o) ->
  '''
    <hr/>
    <p>
      <a href="#{o.step.prev}" class="prev">Previous</a>
      <a href="#{o.step.prev}" class="next">Next</a>
      <a href="#" class="pull-right end">End tour</a>
    </p>
  '''

#
# {Function} Called before showing a popover
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
