# Bootstrap Tour [![Build Status](https://travis-ci.org/FGRibreau/bootstrap-tour.png?branch=master)](https://travis-ci.org/FGRibreau/bootstrap-tour)

Quick and easy product tours with Twitter Bootstrap Popovers.

Fork of the original [sorich87 bootstrap-tour](http://sorich87.github.com/bootstrap-tour/).

New features
------------

- Persistence option `Memory`, `Cookie`, `LocalStorage` via constructor `new Tour({persistence:"LocalStorage"})`
- [Bug fix] Remove event handlers after each step when `reflex:true`

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
var tour = new Tour();

//  Add steps
tour.addStep({
  element: "", /* html element next to which the step popover should be shown */
  title: "", /* title of the popover */
  content: "" /* content of the popover */
});

// Start the tour
tour.start();
</script>
```

## Documentation
[Bootstrap-tour documentation](http://sorich87.github.com/bootstrap-tour/)

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
