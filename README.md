Bootstrap Tour Extended
------------

## [Documentation](http://fgribreau.github.com/bootstrap-tour/docs/bootstrap-tour.js.html)

### Improvement
- `Tour` constructor now accept a `template` attribute thus the `labels.*` attribute has been removed.
- `Tour` now emits an `skip(step)` event when skipping a step because the element is not visible.
- `next()` and `prev()` return promise that is resolved when the popover is shown and that all callbacks have been executed
- If `onShow` (at the `step` level or `Tour` level) returns a promise (see [$.Deferred()](http://api.jquery.com/category/deferred-object/)), Bootstrap-tour will wait until the completition of the promise(s) before displaying the popover
- Persistence option `Memory`, `Cookie`, `LocalStorage` via constructor `new Tour({persistence:"LocalStorage"})`
- `onHide`, `onShow` and `onShown` callbacks now have a second argument `Event` with
  - `{String}` `Event.trigger`:: `api | popover | reflex`
  - `{jQuery}` `Event.element`: the current step element (`onShow` Event does not provides the `element attribute use `onShown` instead)
- `addStep` now accept a function as `element`
- `addStep` and `Tour` constructor now accept `addClass` string attribute, the specified css class will then be added to the popover element
- the popover element now have an automatically added `{tour.name}-step{step.index}` css class

### Bug fix
- In `reflex` mode, leave the same css pointer as it was.
- Don't create unnecessary $() objects
- Remove event handlers after each step when `reflex:true`
- `onHide`, `onShow`, `onShown` callbacks at the step level should not override `onHide`, `onShow`, `onShown` at the tour level

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
