<- $
{run, compile} = require \LiveScript
{any, map, foldl, first, break-list, each, unique} = require \prelude-ls
history = []
autocomplete-history = []


lsc = $ \#ls-console
window.lsc-console = lsc.console do
	prompt-label: '> '
	command-validate: (line) ->
		line != ''
	command-handle: (line) ->
		trimmed-line = line.trim!
		return switch-next-section! if \next! == trimmed-line
		return switch-prev-section! if (\prev! == trimmed-line or \back! == trimmed-line)
		try 
			lines = (history ++ [pre-script]).reduce do
				(acc, a) -> acc + "\n_ = " + a
				""
			line = line.trim!
			compiled =  compile "<- (do)\n" + lines + "\n" + line, bare:true

			autocomplete-list = []
			re = /([\w\-\d]+)\s*=[^=]/ig
			while (m = re.exec compiled) != null
				# add - before upper case letters
				word = m.1.split '' |> foldl do
					(acc, a) ->
						return acc + "-" + a.to-lower-case! if acc.length > 0 and a.to-upper-case! == a 
						acc + a
					''
				autocomplete-list.push word
			autocomplete-history := unique autocomplete-list

			evaluated = eval compiled
			result = evaluated
			return "" if result is undefined
			if "1.1.1" == result.VERSION
				result = "{prelude}"
				class-name = \type
			else
				result-type = typeof! result
				if <[Array Object Number String Boolean]> |> any (result-type ==)
					# serializable types
					class-name = \value
					re = /function.*\((.*)\).*/i; 
					result = JSON.stringify result, (k, v) ->
						if \Function == typeof! v
							# convert function properties to string
							class-name := \type
							[_, args]? = re.exec v.to-string!
							return "(#{args.trim!}) -> ..."
						return v
				else
					# functions
					result = result.to-string!

					# no output for curried functions
					if (result.index-of "_curry.call(context, params) : f.apply(context, params);") > -1
						result = ""
					class-name = \type

			if !no-history
				history.push pre-script if !!pre-script
				history.push line if \Function is not typeof! evaluated?.then # do not add promises to the history
		catch ex
			result = ex.message
			class-name = \error

		command-handled!
		[
			{
				msg: result
				class-name: "jquery-console-message-#{class-name}"
			}
		]
	complete-handle: (line) ->
		line = (/[^a-zA-Z]?(\w.*)/i.exec line)?.1
		return "" if not line
		autocomplete-list = <[next! back!]> ++ autocomplete-history
		autocomplete-list.filter(-> (it.last-index-of line) == 0).map(-> it.substring line.length)
	autofocus: true
	animate-scroll: true
	prompt-history: true
	fade-on-reset: false


window.lsc-reset = ->
	history := []
	lsc-console.reset!

pre-script = null
no-history = false
window.prompt-text = (x-pre, x-no-history, s) ->
	pre-script := x-pre if !!x-pre
	no-history := x-no-history
	lsc-console.prompt-text s

command-handled = ->
	pre-script := null
	no-history := false

$ \.prompt .each ->
	$ @ .click ->
		is-pre = \PRE == @.tag-name

		$me = $ @ 
		x-pre = $me .attr \x-pre
		x-no-history = \String == typeof! $me.attr \x-no-history


		prompt-text do
			x-pre
			x-no-history
			(if is-pre and (\String is not typeof! $me.attr \x-no-linefeed) then "\n" else "") + $me.text!

		lsc-console.focus!


all-paths = do -> first <| ($ 'section[x-path]' .map (-> $ @ .attr \x-path) .to-array!) |> foldl do 
	([acc, skip], a) ->
		skip-next = (a.index-of \/) == -1
		return [acc ++ [a], skip-next] if not skip
		[acc, skip-next]
	[[], false]

$current-section = null
current-path = null
switch-section = (path) ->
	return if not path or not path.length
	lsc-reset!

	$new-section = if (path.index-of \/ ) > -1 then $ "section[x-path='#path']" else $ "section[x-path='#path'] > section:first"
	
	# code to be executed at the start of this step
	$new-section.find 'meta[name=x-pre]' .map (-> $ @ .attr \value) .to-array! 
		|> each -> history.push it

	$current-section.hide! if !!$current-section
	$current-section.parent!.hide! if !!$current-section

	$new-section.parent!.show!
	$new-section.show!

	$current-section := $new-section
	current-path := path

	next-path = get-next-path!
	prev-path = get-prev-path!
	$next-section = $ "section[x-path='#{next-path}']"
	$prev-section = $ "section[x-path='#{prev-path}']"


	[
		[prev-path, ($prev-section.find \h3:first .text!) , ($ \.prev-step)]
		[next-path, ($next-section.find \h3:first .text!) , ($ \.next-step)]
	] |> each ([path, title, $a]) ->
		if !!path
			$a.css \visibility, \visible
			$a.attr \href, '#' + path
			$a.find \span .text title
		else
			$a.css \visibility, \hidden


window.add-event-listener \hashchange, ->
	switch-section <| window.location.hash.substr 1


get-next-path = -> 
	[_, [_, next-path]] = all-paths |> break-list (== current-path)
	next-path

get-prev-path = ->
	[[..., prev-path], _] = all-paths |> break-list (== current-path)
	prev-path

switch-next-section = ->
	next-path = get-next-path!
	return window.location.hash = next-path if !!next-path
	[
		{
			msg: "Out of bounds"
			class-name: "jquery-console-message-error"
		}
	]

switch-prev-section = ->
	prev-path = get-prev-path!
	return window.location.hash = prev-path if !!prev-path
	[
		{
			msg: "Out of bounds"
			class-name: "jquery-console-message-error"
		}
	]


# we like to indent pre tags but html does not, so we fix the indented whitespaces:
$pres = $ \pre .each ->
	$pre = $ @
	lines = $pre.text!.split '\n'
	ws = (/^\s+/.exec lines.0)?.0
	if !!ws
		lines = lines.map (.replace ws, '')
		$pre.text <| lines.join '\n' .trim!


# on load
switch-section <| (window.location.hash.substr 1) or \welcome