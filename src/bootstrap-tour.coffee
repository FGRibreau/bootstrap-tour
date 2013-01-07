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
    dispose: () ->
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
      try
        return JSON.parse(window.localStorage.getItem("#{@ns}#{key}"))
      catch err
        console.error(err)
        return null

  backend =
    Memory: Memory
    Cookie: Cookie
    LocalStorage: LocalStorage

  class Tour
    constructor: (options) ->
      @_options = $.extend(true, {}, Tour.defaults, options)

      # For event handling only
      # Note: I wish I could add underscore as a dependency (or something else)
      @_evt = $('<div/>')
      @on   = $.proxy(@_evt.on, @_evt)
      @off  = $.proxy(@_evt.off, @_evt)
      @one  = $.proxy(@_evt.one, @_evt)

      # Setup persistence
      @persistence = new backend[if @_options.persistence of backend then  @_options.persistence else "Memory"](@_options)

      @_steps = []
      @setCurrentStep()

      # Reshow popover on window resize using debounced resize
      @_onresize(=> @showStep(@_current) unless @ended)

    dispose:() ->
      @_setState("current_step", null)
      @_setState("end", null)
      $.each(@_steps, (i, s) ->
        if s.element? && s.element.popover?
          s.element.popover("hide").removeData("popover")
      )
      $('.popover').remove()
      $.each(@_options.step, (k) => @_options.step[k] = null)
      @_evt.unbind()
      @persistence.dispose()
      $.each(@_options, (k) => @_options[k] = null)


    _setState: (key, value) ->
      @persistence.setState(@_options, key, value)
      @_options.afterSetState(key, value)

    _getState: (key) ->
      value = @persistence.getState(@_options, key)
      @_options.afterGetState(key, value)
      return value

    # Add a new step
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

    # Start tour from current step
    # Returns a Deferred
    start: (force = false) ->
      def = $.Deferred()
      return def.fail("Tour ended").promise() if @ended() && !force

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
    trigger:(name, opt) -> @_evt.triggerHandler(@_initEvent(name, opt))

    # Event object:
    # `{String}` `trigger`: `api | popover | reflex`
    # `{Object}` `step`:
    # `{jQuery}` `element`: the current step element
    # `{Function}` `setPromise(promise)`:
    #     Note that `onShow` Event does not provides the `element` attribute use `onShown` instead)
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

    # Hide current step and show next step
    # Returns a promise
    next:(e) ->
      def = if e and e.def then e.def else $.Deferred()
      @hideStep(@_current, e)
      @showNextStep(def)
      def.promise()

    # Hide current step and show prev step
    # Returns a promise
    prev:(e)->
      def = if e and e.def then e.def else $.Deferred()
      @hideStep(@_current, e)
      @showPrevStep(def)
      def.promise()

    # End tour
    end:(e) ->
      @hideStep(@_current, e)
      $(document).off ".bootstrap-tour"
      @_setState("end", "yes")
      step = @getStep(@_current)
      step.onEnd(@, e) if step and step.onEnd?
      @_options.step.onEnd(@, e) if @_options.step.onEnd isnt step.onEnd

    # Verify if tour is enabled
    ended: ->
      !!@_getState("end")

    ###
    Execute sequentially the array of function
    @param  {Array} arr Array of function that return a promise
    @param  {Object} ctx (optional)
    @return {Deferred}
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
    @return {[type]}       [description]
    ###
    _mapTimes: (times, ipt) ->
        o = []
        while times--
          o.push ipt
        o

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

    # Hide the specified step
    hideStep: (i, e = {}) ->
      step = e.step = @getStep(i)
      $el  = e.element = @getElement(step.element)

      @trigger("hide", e)
      @trigger("hide:step#{step.index}", e)
      # step.onHide(@, e) if step.onHide?
      # @_options.step.onHide(@, e) if @_options.step.onHide isnt step.onHide

      if step.reflex
        $el.css("cursor", "").off("click.tour")

      $el.popover("hide")

    # Wrap if necessary the return call by a deferred
    _deferred: (d) ->
      return d if d and d.done
      # If the function did not returned a promise, return a resolved promise
      return $.Deferred().resolve().promise()

    # Show the specified step
    # i : step number
    # def (optional) the deferred to resolve
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
      @trigger("show:step#{step.index}", step:step, element:false, defs:defs)

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
        @trigger("shown:step#{step.index}", step:step, element:$el)
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

    # Show step popover
    _showPopover: (step, i) ->
      $el     = @getElement(step.element)

      options = $.extend true, {}, @_options

      if step.options
        $.extend options, step.options

      if step.reflex
        $el
          .css("cursor", "pointer")
          .on "click.tour", (e) => @next(trigger:'reflex')

      step.content = @_getProp(step, options.step, "content", step)
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
      if not @_options.keyboard
        return
      $(document).on "keyup.bootstrap-tour", $.proxy(@_onKeyUp, @)

    _onKeyUp: (e) ->
      return unless e.which
      step = @getStep(@_current)
      return if not step
      switch e.which
        # next
        when 39
          e.preventDefault()
          if step.next != -1 and @_current < @_steps.length - 1
            @next()
        # prev
        when 37
          e.preventDefault()
          if step.prev != -1 and @_current > 0
            @prev()




    # The val is a function
    _execOrGet: (val, arg) -> if $.isFunction(val) then val(arg) else val
    # obj : first option
    # objRoot: second option
    # prop: prop to get
    _getProp: (obj, obj2, prop, args...) -> if obj[prop] then @_execOrGet(obj[prop], args...) else @_execOrGet(obj2[prop], args...)


    Tour.defaults =
      #
      # {String} This option is used to build the name of the cookie where the tour state is stored. You can initialize several tours with different names in the same page and application.
      #
      name: "tour"

      #
      # {String} "Cookie" | "LocalStorage" | "Memory" (default "Memory")
      # Note: persistence: "Cookie" requires jquery.cookie.js
      persistence: "Memory"

      #
      # {Boolean} Keyboard navigation
      #
      keyboard: true

      #
      # {Function} Navigation template, `.prev`, `.next` and `.end`
      # will be removed at runtime if necessary
      #
      # The template can be an underscore template or $.tmpl ...
      #
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

      afterSetState: (key, value) ->
      afterGetState: (key, value) ->

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

        #
        # {Function} Function to execute right before each step is shown.
        # If onShow returns a promise (see $.Deferred() documentation), Bootstrap-tour will wait until
        # completition of the promise before displaying the popover
        #
        # Note: if `onShow` is defined at the step level, the two defined `onShow`
        # callbacks will be taken into account in the step.
        onShow: (tour, event) ->

        #
        #  {Function} Function to execute right after each step is shown.
        #
        # Note: if `onShown` is defined at the step level, the two defined `onShown`
        # callbacks will be taken into account in the step.
        onShown: (tour, event) ->

        #
        # {Function} Function to execute right before each step is hidden.
        #
        # Note: if `onHide` is defined at the step level, the two defined `onHide`
        # callbacks will be taken into account in the step.
        onHide: (tour, event) ->

        #
        # {Function} Function to execute on end
        #
        # Note: if `onEnd` is defined at the step level, the two defined `onEnd`
        # callbacks will be taken into account in the step.
        onEnd: (tour, event) ->


  window.Tour = Tour

)(jQuery, window)
