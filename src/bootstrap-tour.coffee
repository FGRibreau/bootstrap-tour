### ============================================================
# Bootstrap-tour extended
#
# Copyright (c) 2013 FG Ribreau (@fgribreau)
# Licensed under the MIT, GPL licenses.
#
# Original version by http://sorich87.github.com/bootstrap-tour/
# ==============================================================
#
###
(($, window) ->
  document = window.document

  class Backend
    dispose: () ->
    setState: (options, key, value) ->
    getState: (options, key) ->

  class Memory extends Backend
    constructor: (options) ->
      @ns = "__db_#{options.name}__"
      window[@ns] = {}
    _avail:() -> window.hasOwnProperty(@ns)
    setState: (options, key, value) ->
      return if !@_avail()
      window[@ns][key] = value
    getState: (options, key) ->
      return if !@_avail()
      window[@ns][key] or null
    dispose: -> delete window[@ns]

  class Cookie extends Backend
    constructor:(options) ->
      @ns = "#{options.name}_"
    setState: (options, key, value) ->
      $.cookie("#{@ns}#{key}", value, { expires: 36500, path: '/' })
    getState: (options, key) ->
      $.cookie("#{@ns}#{key}")

  class LocalStorage extends Backend
    constructor:(options) ->
      @ns = "#{options.name}_"
    setState: (options, key, value) ->
      window.localStorage.setItem("#{@ns}#{key}", JSON.stringify(value))
    getState: (options, key) ->
      item = null
      try
        item = window.localStorage.getItem("#{@ns}#{key}")
        return JSON.parse(item)
      catch err
        console.error(err, item)
        return null

  backend =
    Memory: Memory
    Cookie: Cookie
    LocalStorage: LocalStorage

  class Tour
    ###*
     * @module Public API
    ###

    ###*
     * Create a tour
     * @param  {Object} options An optional option object
     * @return {Tour}
    ###
    constructor: (options) ->
      @_options = $.extend(true, {}, Tour.defaults, options)

      # Step on/off/one
      @_setupEvents()

      # Setup persistence
      @persistence = new backend[if @_options.persistence of backend then  @_options.persistence else "Memory"](@_options)

      @_steps = []
      @setCurrentStep()

      # Reshow popover on window resize using debounced resize
      @_onresize(=> @showStep(@_current) unless @ended)

    ###*
     * Add a step to the tour
     * @param {Object} step An optional object that describe the step
    ###
    addStep: (step) ->
      @_steps.push $.extend({
        #
        #
        #
        index: @_steps.length

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
        # {String | Function(step)} Step title
        #
        title: ""

        #
        # {String | Function(step)} Step content
        #
        content: ""

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

        # #
        # # {Function} Function to execute right before each step is shown.
        # # If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
        # # completition of the promise before displaying the popover
        # #
        # onShow: (tour, event) ->

        # #
        # # {Function} Function to execute right after each step is shown.
        # #
        # onShown: (tour, event) ->

        # #
        # # {Function} Function to execute right before each step is hidden.
        # #
        # onHide: (tour, event) ->

        # #
        # # {Function} Function to execute on end
        # #
        # onEnd: (tour, event) ->
      }, step)
      @

    ###*
     * Cleanly remove the Tour
    ###
    dispose:() ->
      @_setState("current_step", null)
      @_setState("end", null)

      $.each(@_steps, (i, s) ->
        if s.element? && s.element.popover?
          s.element.popover("hide").removeData("popover")
      ) if @_steps

      # Remove elements
      $('.popover, #bootstrap-tour-style, #bootstrap-tour-overlay').remove()
      $(document).off("click.bootstrap-tour, keyup.bootstrap-tour")
      # Remove listeners
      @_evt.off()
      # Clean persistence
      @persistence.dispose()

      $.each(@_options.step, (k) => @_options.step[k] = null)  if @_options.step
      $.each(@_options, (k) => @_options[k] = null)

    # Get a step by its indice
    getStep: (i) ->
      $.extend({
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
      }, @_steps[i]) if @_steps[i]?

    ###*
     * Start tour from current step
     * @param  {Boolean} force If force is set to `true` the tour will be forced to start
     * @return {Promise}       Promise that will be resolved when the step is shown
    ###
    start: (force = false) ->
      def = $.Deferred()
      return def.reject("Tour ended").promise() if @ended() && !force

      # Go to next step after click on element with class .next
      $(document).off("click.bootstrap-tour",".popover .next").on "click.bootstrap-tour", ".popover .next", (e) =>
        e.preventDefault()
        @next(trigger:'popover')

      # Go to previous step after click on element with class .prev
      $(document).off("click.bootstrap-tour",".popover .prev").on "click.bootstrap-tour", ".popover .prev", (e) =>
        e.preventDefault()
        @prev(trigger:'popover')

      # End tour after click on element with class .end
      $(document).off("click.bootstrap-tour",".popover .end").on "click.bootstrap-tour", ".popover .end", (e) =>
        e.preventDefault()
        @end(trigger:'popover')

      @_setupKeyboardNavigation()
      @showStep(@_current, def)
      def.promise()

    #
    # Trigger callbacks for the given event
    #
    trigger:(name, e = {}) ->
      @_evt.triggerHandler(@_initEvent(name, e))
      @_evt.triggerHandler(@_initEvent("#{name}:step#{e.step.index}", e)) if e.step

    # Hide current step and show next step
    # Returns a promise
    next:(e) ->
      def = if e and e.def then e.def else $.Deferred()
      @hideStep(@_current, e)
      @showNextStep(def)
      def.promise()

    # Hide current step and show prev step
    # Returns a promise
    prev:(trigger = "api")->
      def = $.Deferred()
      @hideStep(@_current, trigger:trigger)
      @showPrevStep(def)
      def.promise()

    # End tour
    end:(trigger = "api") ->
      step       = @getStep(@_current)
      e          = step:step, trigger:trigger

      @hideStep(@_current, e)
      @_setState("end", "yes")
      $(document).off ".bootstrap-tour"

      @trigger("end", e)

    # Verify if tour is enabled
    ended: ->
      !!@_getState("end")

    ###
    Goto a step by its index
    ###
    gotoStep: (index) -> @_when @_mapTimes(index, @.next), @

    # Restart tour
    restart: ->
      @_setState("current_step", null)
      @_setState("end", null)
      @setCurrentStep(0)
      @start()

    #
    # @param  {Mixed} element
    # @return {jQuery}      a jQuery object
    getElement: (el) ->
      if typeof el is 'function'
        el = el()
      if !el
        return $()
      if el instanceof jQuery
        return el
      return $(el)

    ###*
     * Hide the specified step
     * @param  {Number} i  Step index
     * @param  {Event} e   Event
     * @optional
    ###
    hideStep: (i, e = {}) ->
      step = e.step = @getStep(i)
      $el  = e.element = @getElement(step.element)

      @trigger("hide", e)

      if step.reflex
        $el.css("cursor", "").off("click.tour")
      $el.popover("hide")

      if @_getProp(step, @_options.step, "overlay", step)
        @_toggleOverlay($el, false)

      @trigger("hidden", e)

    ###*
     * Show the specified step
     * @param  {Number} i     Step index
     * @param  {Deferred} def A deferred that will be resolved when the popover will be shown or reject if the step was not found
     * @optional
    ###
    showStep: (i, def) ->
      step = @getStep(i)

      unless step
        def.reject("Step #{i} undefined") if def
        return

      @setCurrentStep(i)

      # Redirect to step path if not already there
      # Compare to path, then filename
      if step.path != "" && document.location.pathname != step.path && document.location.pathname.replace(/^.*[\\\/]/, '') != step.path
        document.location.href = step.path
        return

      defs = []
      @trigger("show", step:step, element:false, defs:defs)

      $.when.apply($, defs).always(() =>
        $el = @getElement(step.element)

        # If step element is hidden or does not exist, skip step
        if $el.length is 0 or not $el.is(":visible")
          @trigger("skipping", element:$el, step:step)
          # @showNextStep(def)
          @next(def:def)
          return

        # Show popover
        @_showPopover(step, i)
        @trigger("shown", step:step, element:$el)
        # step.onShown(@, e) if step.onShown?
        # @_options.step.onShown(@, e) if @_options.step.onShown isnt step.onShown

        def.resolve() if def
      )

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @_setState("current_step", value)
      else
        @_current = @_getState("current_step")
        if not @_current or @_current is "null"
          @_current = 0
        else
          @_current = parseInt(@_current, 10)

    # Show next step
    showNextStep: (def) ->
      step = @getStep(@_current)
      @showStep(step.next, def)

    # Show prev step
    showPrevStep: (def) ->
      step = @getStep(@_current)
      @showStep(step.prev, def)

    ###*
     * @module Private API
    ###

    ###*
     * Persist the state
     * @param {String} key
     * @param {Mixed} value
    ###
    _setState: (key, value) ->
      @persistence.setState(@_options, key, value)

    _getState: (key) ->
      value = @persistence.getState(@_options, key)
      return value

    ###*
     * [_setupEvents description]
     * @return {[type]} [description]
    ###
    _setupEvents: () ->
      # Note: I wish I could add underscore as a dependency (or something else)
      @_evt = $('<div/>')
      @on   = @_chainable(@_evt.on, @_evt)
      @off  = @_chainable(@_evt.off, @_evt)
      @one  = @_chainable(@_evt.one, @_evt)

    # Event object:
    #
    #
    #
    #
    #

    ###*
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
    ###
    _initEvent: (name = "", opt = {}) ->
      e = jQuery.Event(name)
      $.extend(e, opt)

      if e.defs
        defs = e.defs
        e.setPromise = (promise) -> defs.push(promise)
        delete e.defs

      e.trigger = "api" if !e.trigger
      step = e.step = @getStep(@_current) if !e.step
      if name == "show" or name.indexOf("show:") == 0
        delete e.element
      else if step
        e.element = @getElement(step.element)
      e

    _toggleOverlay:($el, display) ->
      @_injectOverlay()

      if !display
        $('#bootstrap-tour-overlay').fadeOut(300, () ->
          $el.removeClass('bootstrap-tour-expose').css('z-index','1')
          $('.popover.bootstrap-tour').removeClass('expose')
          pos = $el.data('old-pos')
          $el.css('position', pos).removeData('old-pos') if pos
        )
        return

      $el.addClass('bootstrap-tour-expose').css('z-index','99999')
      pos = $el.css('position')
      if pos isnt 'absolute'
        $el.data('old-pos', pos)
        $el.css('position', 'relative')
      $('.popover.bootstrap-tour').addClass('expose').css('z-index','99999')
      $('#bootstrap-tour-overlay')
        .width($(document.body).outerWidth())
        .height($(document.body).outerHeight())
        .fadeIn(300)

    _injectOverlay: () ->
      return if $('style#bootstrap-tour-style').length > 0
      $("<style id='bootstrap-tour-style' type='text/css'>#{@_options.style()}</style>").appendTo('head')
      $("<div id='bootstrap-tour-overlay'></div>").appendTo('body')

    ###*
     * Show step popover
     * @ignore
     * @param  {Object} step
     * @param  {Number} i    step number
    ###
    _showPopover: (step, i) ->
      $el          = @getElement(step.element)
      options      = $.extend true, {}, @_options
      step.content = @_getProp(step, options.step, "content", step)

      if step.options
        $.extend options, step.options

      if @_getProp(step, options.step, "reflex", step)
        $el.css("cursor", "pointer").on("click.tour", (e) => @next(trigger:'reflex'))

      $nav = $(options.template(step)).wrapAll('<div/>').parent()

      if step.prev == -1
        $nav.find('.prev').remove()
      if step.next == -1
        $nav.find('.next').remove()

      content = $nav.html()
      $nav.remove()

      $el.popover({
        placement: step.placement
        trigger: "manual"
        title: @_getProp(step, options.step, "title", step)
        content: content
        html: true
        animation: step.animation
      })

      popover = $el.data("popover")
      tip     = popover.tip().addClass("bootstrap-tour #{options.name}-step#{i} #{options.step.addClass} #{step.addClass}")
      popover.show()

      if @_getProp(step, options.step, "overlay", step)
        @_toggleOverlay($el, true)

      @_reposition(tip)
      @_scrollIntoView(tip)

    ###*
     * Prevent popups from crossing over the edge of the window
     * @param  {jQuery} tip popover tip
    ###
    _reposition: (tip) ->
      tipOffset = tip.offset()
      offsetBottom = $(document).outerHeight() - tipOffset.top - $(tip).outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $(document).outerWidth() - tipOffset.left - $(tip).outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0
      tip.offset(tipOffset)

    ###*
     * Scroll to the popup if it is not in the viewport
     * @param  {jQuery} tip popover tip
    ###
    _scrollIntoView: (tip) ->
      tipRect = tip.get(0).getBoundingClientRect()
      unless tipRect.top > 0 && tipRect.bottom < $(window).height() && tipRect.left > 0 && tipRect.right < $(window).width()
        tip.get(0).scrollIntoView(true)

    ###*
     * When the user resize the window
     * @ignore
     * @param  {Function} fn      Callback function
     * @param  {Number}   timeout How much time to wait after the last `resize` event before firing fn
    ###
    _onresize: (fn, timeout) ->
      $(window).resize ->
        clearTimeout(timeout)
        timeout = setTimeout(fn, 100)

    ###*
     * Activate if necessary the keyboard navigation
    ###
    _setupKeyboardNavigation: ->
      return if not @_options.keyboard
      $(document).on "keyup.bootstrap-tour", $.proxy(@_onKeyUp, @)

    ###*
     * When the key is up
     * @param  {Event} e jQuery event
     * @todo Handle escape key -> end the tour
     * @ignore
    ###
    _onKeyUp: (e) ->
      return unless e.which
      step = @getStep(@_current)
      return if not step
      switch e.which
        # next
        when 39
          e.preventDefault()
          if step.next != -1 and @_current < @_steps.length - 1
            @next(trigger:"keyboard")
        # prev
        when 37
          e.preventDefault()
          if step.prev != -1 and @_current > 0
            @prev(trigger:"keyboard")

    ###*
     * Execute sequentially the array of function
     * @param  {Array} arr  an array of function that return a promise
     * @param  {Object} ctx context
     * @ignore
     * @return {Deferred}
    ###
    _when: (arr, ctx) ->
      def = $.Deferred()
      next = ->
        fn = arr.shift()
        return def.resolve()  unless fn
        fn.call(ctx).then next
      next()
      def.promise()


    ###
    Returns an array of `ipt` `times` times
    @param  {[type]} count [description]
    @param  {[type]} ipt   [description]
    @ignore
    @return {[type]}       [description]
    ###
    _mapTimes: (times, ipt) ->
        o = []
        while times--
          o.push ipt
        o

    ###*
     * Get the a property `prop` from `obj1` if present or from obj2 otherwise and transfer
     * arguments `args` if the property is a function
     * @param  {Object} obj1    First object
     * @param  {Object} obj2    Second Object
     * @param  {String} prop    Property name
     * @param  {Array} args...  Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}
    ###
    _getProp: (obj1, obj2, prop, args...) -> if obj1[prop] then @_execOrGet(obj1[prop], args...) else @_execOrGet(obj2[prop], args...)

    ###*
     * Get the value of `val`, it handles the case when `val` is a function
     * @param  {Mixed} val Value
     * @param  {Array} arg Array of arguments
     * @optional
     * @ignore
     * @return {Mixed}     `val` value
    ###
    _execOrGet: (val, args...) -> if $.isFunction(val) then val(args...) else val

    ###*
     * Make a function chainable inside `Tour`
     * @param  {Function} fn  function
     * @param  {Object}   ctx Context
     * @return {Function}     Chainable function that returns the current Tour instance
     * @ignore
    ###
    _chainable:(fn, ctx) ->
      (args...) =>
        fn.apply(ctx, args)
        @

    ###*
     * `Tour` constructor `option` defaults
     * @type {Object}
    ###
    Tour.defaults =
      ###*
       * This option is used to build the name of the cookie where the tour state is stored.
       * You can initialize several tours with different names in the same page and application.
       * @type {String}
      ###
      name: "tour"

      ###*
       * How to handle persistence
       *
       * @type {String} Backend name
       * @description The value can be "Cookie" | "LocalStorage" | "Memory" (default "Memory")
       *              Note: the "Cookie" backend requires jquery.cookie.js
      ###
      persistence: "Memory"

      ###*
       * Keyboard navigation
       * @type {Boolean} true if activated, false otherwise
      ###
      keyboard: true

      ###*
       * Bootstrap-tour template
       * @description Navigation template, `.prev`, `.next` and `.end`
       *              will be removed at runtime if necessary.
       *              The template can be an underscore template or $.tmpl ...
       *
       * @param  {Object} step The step to render
       * @return {String}      A string containing the HTML that will be injected into the popover
      ###
      template:(step) ->
        """
          <p>#{step.content}</p>
          <hr/>
          <p>
            <a href="#{step.prev}" class="prev">Previous</a>
            <a href="#{step.next}" class="next">Next</a>
            <a href="#" class="pull-right end">End tour</a>
          </p>
        """

      style:() ->
        """
        .popover.bootstrap-tour.expose{z-index:99998;}
        #bootstrap-tour-overlay{background:rgba(0,0,0,0.5);display:none;width:100%;height:100%;position:absolute; top:0; left:0; z-index:99997;}
        """

      #
      # Global step settings shared between the steps
      #
      step:
        #
        # {String | Function(step)} Default step title
        #
        title:null

        #
        # {String | Function(step)} Default step content
        #
        content:null

        #
        # {String} Css class to add to the .popover element
        #
        # Note: if `addClass` is defined at the step level, the two defined `addClass` will
        # be taken into account in the popover
        addClass:""

        ###*
         * Globally enable an overlay for each step element
         * @type {Boolean} true if activated, false otherwise
         * @todo Handle Bootstrap modal, pull requests are welcome !
        ###
        overlay: false

        #
        # {Boolean} Globally enable the reflex mode, click on the element to continue the tour
        #
        reflex: false

        # #
        # # {Function} Function to execute right before each step is shown.
        # # If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
        # # completition of the promise before displaying the popover
        # #
        # # Note: if `onShow` is defined at the step level, the two defined `onShow`
        # # callbacks will be taken into account in the step.
        # onShow: (tour, event) ->

        # #
        # #  {Function} Function to execute right after each step is shown.
        # #
        # # Note: if `onShown` is defined at the step level, the two defined `onShown`
        # # callbacks will be taken into account in the step.
        # onShown: (tour, event) ->

        # #
        # # {Function} Function to execute right before each step is hidden.
        # #
        # # Note: if `onHide` is defined at the step level, the two defined `onHide`
        # # callbacks will be taken into account in the step.
        # onHide: (tour, event) ->

        # #
        # # {Function} Function to execute on end
        # #
        # # Note: if `onEnd` is defined at the step level, the two defined `onEnd`
        # # callbacks will be taken into account in the step.
        # onEnd: (tour, event) ->


  window.Tour = Tour
)(jQuery, window)
