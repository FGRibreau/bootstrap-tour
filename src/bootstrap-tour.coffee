### ============================================================
# bootstrap-tour.js v0.1
# http://sorich87.github.com/bootstrap-tour/
# ==============================================================
#
# Copyright (c) 2013 FG Ribreau
# Licensed under the MIT, GPL licenses.
###

(($, window) ->
  document = window.document

  class Backend
    setState: (options, key, value) ->
    getState: (options, key) ->

  class Memory extends Backend
    constructor: (options) ->
      @ns = "__db_#{options.name}__"
      window[@ns] = {}
    setState: (options, key, value) ->
      window[@ns][key] = value
    getState: (options, key) ->
      window[@ns][key] or null

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
      window.localStorage.setItem("#{@ns}#{key}", value)
    getState: (options, key) ->
      window.localStorage.getItem("#{@ns}#{key}")

  backend =
    Memory: Memory
    Cookie: Cookie
    LocalStorage: LocalStorage

  class Tour
    constructor: (options) ->
      @_options = $.extend({}, Tour.defaults, options)

      # Setup persistence
      @persistence = new backend[if @_options.persistence of backend then  @_options.persistence else "Memory"](@_options);

      @_steps = []
      @setCurrentStep()

      # Reshow popover on window resize using debounced resize
      @_onresize(=> @showStep(@_current) unless @ended)

    setState: (key, value) ->
      @persistence.setState(@_options, key, value);
      @_options.afterSetState(key, value)

    getState: (key) ->
      value = @persistence.getState(@_options, key);
      @_options.afterGetState(key, value)
      return value

    # Add a new step
    addStep: (step) ->
      @_steps.push step

    # Get a step by its indice
    getStep: (i) ->
      $.extend({
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
      }, @_steps[i]) if @_steps[i]?

    # Start tour from current step
    start: (force = false) ->
      return if @ended() && !force

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

      @showStep(@_current)

    _initEvent: (e = {}) ->
      e.trigger = "api" if !e.trigger
      step = @getStep(@_current)
      if step and !e.element
        e.element = @getElement(step.element)
      e

    # Hide current step and show next step
    next:(e) ->
      @hideStep(@_current, @_initEvent(e))
      @showNextStep()

    # Hide current step and show prev step
    prev:(e)->
      @hideStep(@_current, @_initEvent(e))
      @showPrevStep()

    # End tour
    end:(e) ->
      @hideStep(@_current, @_initEvent(e))
      $(document).off ".bootstrap-tour"
      @setState("end", "yes")

    # Verify if tour is enabled
    ended: ->
      !!@getState("end")

    # Restart tour
    restart: ->
      @setState("current_step", null)
      @setState("end", null)
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

    # Hide the specified step
    hideStep: (i, e) ->
      e = @_initEvent() if !e
      step = @getStep(i)
      $el = @getElement(step.element)
      step.onHide(@, e) if step.onHide?
      @_options.onHide(@, e) if @_options.onHide isnt step.onHide

      if step.reflex
        $el.css("cursor", "auto").off("click.tour")

      $el.popover("hide")

    # Wrap if necessary the return call by a deferred
    _deferred: (d) ->
      return d if d and d.done
      # If the function did not returned a promise, return a resolved promise
      return $.Deferred().resolve().promise()

    # Show the specified step
    showStep: (i) ->
      step = @getStep(i)

      return unless step

      $el = @getElement(step.element)
      @setCurrentStep(i)

      # Redirect to step path if not already there
      # Compare to path, then filename
      if step.path != "" && document.location.pathname != step.path && document.location.pathname.replace(/^.*[\\\/]/, '') != step.path
        document.location.href = step.path
        return

      e = @_initEvent()

      defs = []
      defs.push(@_deferred(step.onShow(@, e))) if step.onShow?
      defs.push(@_deferred(@_options.onShow(@, e))) if @_options.onShow isnt step.onShow

      $.when.apply($, defs).always(() =>
        # If step element is hidden, skip step
        unless step.element? && $el.length != 0 && $el.is(":visible")
          @showNextStep()
          return

        # Show popover
        @_showPopover(step, i)

        step.onShown(@, e) if step.onShown?
        @_options.onShown(@, e) if @_options.onShown isnt step.onShown
      )

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @setState("current_step", value)
      else
        @_current = @getState("current_step")
        if not @_current
          @_current = 0
        else
          @_current = parseInt(@_current, 10)

    # Show next step
    showNextStep: ->
      step = @getStep(@_current)
      @showStep(step.next)

    # Show prev step
    showPrevStep: ->
      step = @getStep(@_current)
      @showStep(step.prev)

    # Show step popover
    _showPopover: (step, i) ->
      $el     = @getElement(step.element)

      options = $.extend {}, @_options

      if step.options
        $.extend options, step.options

      if step.reflex
        $el
          .css("cursor", "pointer")
          .on "click.tour", (e) => @next(trigger:'reflex')

      $nav = $(options.(step)).wrapAll('<div/>').parent()

      if step.prev == 0
        $nav.find('.prev').remove()
      if step.next == 0
        $nav.find('.next').remove()

      content = $nav.html()
      $nav.remove();

      $el.popover({
        placement: step.placement
        trigger: "manual"
        title: step.title
        content: content
        html: true
        animation: step.animation
      });

      popover = $el.data("popover")
      tip     = popover.tip().addClass("#{options.name}-step#{i} #{options.addClass} #{step.addClass}")
      popover.show()
      @_reposition(tip)
      @_scrollIntoView(tip)

    # Prevent popups from crossing over the edge of the window
    _reposition: (tip) ->
      tipOffset = tip.offset()
      offsetBottom = $(document).outerHeight() - tipOffset.top - $(tip).outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $(document).outerWidth() - tipOffset.left - $(tip).outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0
      tip.offset(tipOffset)

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (tip) ->
      tipRect = tip.get(0).getBoundingClientRect()
      unless tipRect.top > 0 && tipRect.bottom < $(window).height() && tipRect.left > 0 && tipRect.right < $(window).width()
        tip.get(0).scrollIntoView(true)

    # Debounced window resize
    _onresize: (cb, timeout) ->
      $(window).resize ->
        clearTimeout(timeout)
        timeout = setTimeout(cb, 100)

    # Keyboard navigation
    _setupKeyboardNavigation: ->
      if @_options.keyboard
        $(document).on "keyup.bootstrap-tour", (e) =>
          return unless e.which
          switch e.which
            when 39
              e.preventDefault()
              if @_current < @_steps.length - 1
                @next()
            when 37
              e.preventDefault()
              if @_current > 0
                @prev()


    Tour.defaults =
      #
      # {String} This option is used to build the name of the cookie where the tour state is stored. You can initialize several tours with different names in the same page and application.
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
      # {Function} Function to execute right before each step is shown.
      # If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
      # completition of the promise before displaying the popover
      #
      onShow: (tour, event) ->

      #
      # {Function} Function to execute right after each step is shown.
      #
      onShown: (tour, event) ->

      #
      # {Function} Function to execute right before each step is hidden.
      #
      onHide: (tour, event) ->

      afterSetState: (key, value) ->
      afterGetState: (key, value) ->

  window.Tour = Tour

)(jQuery, window)
