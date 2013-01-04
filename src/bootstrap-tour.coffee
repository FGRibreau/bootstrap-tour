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
        path: ""
        placement: "right"
        title: ""
        content: ""
        next: if i == @_steps.length - 1 then -1 else i + 1
        prev: i - 1
        addClass:""
        animation: true
        reflex: false
        onShow: $.noop
        onHide: $.noop
        onShown: $.noop
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


      step.onShow(@, @_initEvent()) if step.onShow?
      @_options.onShow(@, @_initEvent()) if @_options.onShow isnt step.onShow

      # If step element is hidden, skip step
      unless step.element? && $el.length != 0 && $el.is(":visible")
        @showNextStep()
        return

      # Show popover
      @_showPopover(step, i)

      step.onShown(@, @_initEvent()) if step.onShown?
      @_options.onShown(@, @_initEvent()) if @_options.onShown isnt step.onShown

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
      content = "#{step.content}"
      $el     = @getElement(step.element)

      options = $.extend {}, @_options

      if step.options
        $.extend options, step.options

      if step.reflex
        $el
          .css("cursor", "pointer")
          .on "click.tour", (e) => @next(trigger:'reflex')

      $nav = $(options.template(step:step)).wrapAll('<div/>').parent()

      if step.prev == 0 or options.hidePrev
        $nav.find('.prev').remove()
      if step.next == 0
        $nav.find('.next').remove()

      content += $nav.html()
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

  window.Tour = Tour

)(jQuery, window)
