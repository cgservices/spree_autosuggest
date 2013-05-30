class @Autosuggest
  constructor: (selector, options = {}) ->
    @search_field = $(selector)
    return if @search_field.length == 0

    @settings =
      to_display: 5
      strict_cache: false
    @settings = $.extend @settings, options

    @cache = {}

    $.extend true, $.ui.autocomplete::, @extension_methods()
    @search_field.autocomplete(
      @settings,
      source: (request, response) =>
        @finder(request, response)
      select: (event, ui) =>
        location.href = ui.item.url
      )

  # TODO: rewrite
  fire_keybinds: (event) ->
    if event.keyCode == $.ui.keyCode.RIGHT
      elem = $(@search_field.data("autocomplete").menu.active).find("a")
      if elem.length > 0
        elem.trigger("click")
      else
        $("li.ui-menu-item:first a").trigger("mouseenter").trigger("click")

  finder: (request, response) ->
    term = request.term.toLowerCase()
    cached = @from_cache(term)
    return response cached if cached
    $.getJSON "/suggestions", request, (data) =>
      @cache[term] = data
      response @from_cache(term)

  from_cache: (term) ->
    result = false
    $.each @cache, (key, data) =>
      if (if @settings.strict_cache then term is key else term.indexOf(key) is 0)
        result = @filter_terms(data, term).slice(0, @settings.to_display)
    result

  filter_terms: (array, term) ->
      matcher = new RegExp("\\b" + $.ui.autocomplete.escapeRegex(term), "i")
      $.grep array, (value) =>
        source = value.keywords or value.value or value
        return true if matcher.test(source)

  extension_methods: ->
    _renderItem: (ul, item) ->
        item.label = item.label.replace(new RegExp("(" + $.ui.autocomplete.escapeRegex(@term) + ")", "gi"), "<strong>$1</strong>")
        $("<li></li>").data("item.autocomplete", item).append("<a>" + item.label + "</a>").appendTo ul
