<- $
{run, compile} = require \LiveScript
{any} = require \prelude-ls
history = []

lsc = $ \#ls-console
window.lsc-console = lsc.console do
	prompt-label: '> '
	command-validate: (line) ->
		line != ''
	command-handle: (line) ->
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