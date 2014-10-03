<- $
{run, compile} = require \LiveScript
{any, foldl, first, break-list} = require \prelude-ls
history = []

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
			result = eval compile "<- (do)\n" + lines + "\n" + line, bare:true
			if "1.1.1" == result.VERSION
				result = "{prelude}"
				class-name = \type
			else
				result-type = typeof! result
				if <[Array Object Number String Boolean]> |> any (result-type ==)
					class-name = \value
					re = /function.*\((.*)\).*/i; 
					result = JSON.stringify result, (k, v) ->
						if \Function == typeof! v
							class-name := \type
							[_, args]? = re.exec v.toString!
							if !args and !args?.trim
								debugger;
							return "(#{args.trim!}) -> ..."
						return v
				else
					result = result.toString!
					class-name = \type

			if !no-history
				history.push pre-script if !!pre-script
				history.push line
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

		x-pre = $ @ .attr \x-pre
		x-no-history = "String" == typeof! $ @ .attr \x-no-history


		prompt-text do
			x-pre
			x-no-history
			(if is-pre then "\n" else "") + $ @ .text!

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
	lsc-console.reset!

	$new-section = if (path.index-of \/ ) > -1 then $ "section[x-path='#path']" else $ "section[x-path='#path'] > section:first"
	
	$current-section.hide! if !!$current-section
	$current-section.parent!.hide! if !!$current-section

	$new-section.parent!.show!
	$new-section.show!

	$current-section := $new-section
	current-path := path
	window.location.hash = path

window.add-event-listener \hashchange, ->
	switch-section <| window.location.hash.substr 1


switch-next-section = ->
	[_, [_, next-path]] = all-paths |> break-list (== current-path)
	return switch-section next-path if !!next-path
	[
		{
			msg: "Out of bounds"
			class-name: "jquery-console-message-error"
		}
	]

switch-prev-section = ->
	[[..., prev-path], _] = all-paths |> break-list (== current-path)
	return switch-section prev-path if !!prev-path
	[
		{
			msg: "Out of bounds"
			class-name: "jquery-console-message-error"
		}
	]

# on load
switch-section <| (window.location.hash.substr 1) or \welcome