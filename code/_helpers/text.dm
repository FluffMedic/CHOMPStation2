/*
 * Holds procs designed to help with filtering text
 * Contains groups:
 *			SQL sanitization
 *			Text sanitization
 *			Text searches
 *			Text modification
 *			Misc
 */

GLOBAL_LIST_INIT(alphabet_upper, list("A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"))

/*
 * SQL sanitization
 */

// Run all strings to be used in an SQL query through this proc first to properly escape out injection attempts.
/proc/sanitizeSQL(var/t as text)
	//var/sqltext = dbcon.Quote(t);
	//return copytext(sqltext, 2, length(sqltext));//Quote() adds quotes around input, we already do that
	return t

/proc/format_table_name(table as text)
	//return CONFIG_GET(string/feedback_tableprefix) + table
	return table // We don't implement tableprefix

/*
 * Text sanitization
 */
// Can be used almost the same way as normal input for text
/proc/clean_input(Message, Title, Default, mob/user)
	var/txt = input(user, Message, Title, Default) as text | null
	if(txt)
		return html_encode(txt)

//Simply removes < and > and limits the length of the message
/proc/strip_html_simple(var/t,var/limit=MAX_MESSAGE_LEN)
	var/list/strip_chars = list("<",">")
	t = copytext(t,1,limit)
	for(var/char in strip_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + copytext(t, index+1)
			index = findtext(t, char)
	return t

//Runs byond's sanitization proc along-side strip_html_simple
//I believe strip_html_simple() is required to run first to prevent '<' from displaying as '&lt;' that html_encode() would cause
/proc/adminscrub(var/t,var/limit=MAX_MESSAGE_LEN)
	return copytext((html_encode(strip_html_simple(t))),1,limit)

//Used for preprocessing entered text
/proc/sanitize(var/input, var/max_length = MAX_MESSAGE_LEN, var/encode = 1, var/trim = 1, var/extra = 1)
	if(!input)
		return

	if(max_length)
		input = copytext(input,1,max_length)

	if(extra)
		input = replacetext(input, new/regex("^\[\\n\]+|\[\\n\]+$", "g"), "")// strip leading and trailing new lines
		var/temp_input = replace_characters(input, list("\n"="  ","\t"=" "))//one character is replaced by two
		if(length(input) < (length(temp_input) - 18))//18 is the number of linebreaks allowed per message
			input = replace_characters(temp_input,list("  "=" "))//replace again, this time the double spaces with single ones

	if(encode)
		// The below \ escapes have a space inserted to attempt to enable CI auto-checking of span class usage. Please do not remove the space.
		//In addition to processing html, html_encode removes byond formatting codes like "\ red", "\ i" and other.
		//It is important to avoid double-encode text, it can "break" quotes and some other characters.
		//Also, keep in mind that escaped characters don't work in the interface (window titles, lower left corner of the main window, etc.)
		input = html_encode(input)
	else
		//If not need encode text, simply remove < and >
		//note: we can also remove here byond formatting codes: 0xFF + next byte
		input = replace_characters(input, list("<"=" ", ">"=" "))

	if(trim)
		//Maybe, we need trim text twice? Here and before copytext?
		input = trim(input)

	return input

//Run sanitize(), but remove <, >, " first to prevent displaying them as &gt; &lt; &34; in some places, after html_encode().
//Best used for sanitize object names, window titles.
//If you have a problem with sanitize() in chat, when quotes and >, < are displayed as html entites -
//this is a problem of double-encode(when & becomes &amp;), use sanitize() with encode=0, but not the sanitizeSafe()!
/proc/sanitizeSafe(var/input, var/max_length = MAX_MESSAGE_LEN, var/encode = 1, var/trim = 1, var/extra = 1)
	return sanitize(replace_characters(input, list(">"=" ","<"=" ", "\""="'")), max_length, encode, trim, extra)

//Filters out undesirable characters from names
/proc/sanitizeName(var/input, var/max_length = MAX_NAME_LEN, var/allow_numbers = 0)
	if(!input || length(input) > max_length)
		return //Rejects the input if it is null or if it is longer then the max length allowed

	var/number_of_alphanumeric	= 0
	var/last_char_group			= 0
	var/output = ""

	for(var/i=1, i<=length(input), i++)
		var/ascii_char = text2ascii(input,i)
		switch(ascii_char)
			// A  .. Z
			if(65 to 90)			//Uppercase Letters
				output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// a  .. z
			if(97 to 122)			//Lowercase Letters
				if(last_char_group<2)		output += ascii2text(ascii_char-32)	//Force uppercase first character
				else						output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 4

			// 0  .. 9
			if(48 to 57)			//Numbers
				if(!allow_numbers)			continue	// If allow_numbers is 0, then don't do this.
				output += ascii2text(ascii_char)
				number_of_alphanumeric++
				last_char_group = 3

			// '  -  .
			if(39,45,46)			//Common name punctuation
				if(!last_char_group) continue
				output += ascii2text(ascii_char)
				last_char_group = 2

			// ~   |   @  :  #  $  %  &  *  +
			if(126,124,64,58,35,36,37,38,42,43)			//Other symbols that we'll allow (mainly for AI)
				if(!last_char_group)		continue	//suppress at start of string
				if(!allow_numbers)			continue
				output += ascii2text(ascii_char)
				last_char_group = 2

			//Space
			if(32)
				if(last_char_group <= 1)	continue	//suppress double-spaces and spaces at start of string
				output += ascii2text(ascii_char)
				last_char_group = 1
			else
				return

	if(number_of_alphanumeric < 2)	return		//protects against tiny names like "A" and also names like "' ' ' ' ' ' ' '"

	if(last_char_group == 1)
		output = copytext(output,1,length(output))	//removes the last character (in this case a space)

	for(var/bad_name in list("space","floor","wall","r-wall","monkey","unknown","inactive ai","plating"))	//prevents these common metagamey names
		if(cmptext(output,bad_name))	return	//(not case sensitive)

	return output

//Returns null if there is any bad text in the string
/proc/reject_bad_text(var/text, var/max_length=512)
	if(length(text) > max_length)	return			//message too long
	var/non_whitespace = 0
	for(var/i=1, i<=length(text), i++)
		switch(text2ascii(text,i))
			if(62,60,92,47)	return			//rejects the text if it contains these bad characters: <, >, \ or /
			if(127 to 255)	return			//rejects weird letters like �
			if(0 to 31)		return			//more weird stuff
			if(32)			continue		//whitespace
			else			non_whitespace = 1
	if(non_whitespace)		return text		//only accepts the text if it has some non-spaces


//Old variant. Haven't dared to replace in some places.
/proc/sanitize_old(var/t,var/list/repl_chars = list("\n"="#","\t"="#"))
	return html_encode(replace_characters(t,repl_chars))


//Removes a few problematic characters
/proc/sanitize_simple(t,list/repl_chars = list("\n"="#","\t"="#"))
	for(var/char in repl_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + repl_chars[char] + copytext(t, index + length(char))
			index = findtext(t, char, index + length(char))
	return t

/proc/sanitize_filename(t)
	return sanitize_simple(t, list("\n"="", "\t"="", "/"="", "\\"="", "?"="", "%"="", "*"="", ":"="", "|"="", "\""="", "<"="", ">"=""))

/*
 * Text searches
 */

//Checks the beginning of a string for a specified sub-string
//Returns the position of the substring or 0 if it was not found
/proc/dd_hasprefix(text, prefix)
	var/start = 1
	var/end = length(prefix) + 1
	return findtext(text, prefix, start, end)

//Checks the beginning of a string for a specified sub-string. This proc is case sensitive
//Returns the position of the substring or 0 if it was not found
/proc/dd_hasprefix_case(text, prefix)
	var/start = 1
	var/end = length(prefix) + 1
	return findtextEx(text, prefix, start, end)

//Checks the end of a string for a specified substring.
//Returns the position of the substring or 0 if it was not found
/proc/dd_hassuffix(text, suffix)
	var/start = length(text) - length(suffix)
	if(start)
		return findtext(text, suffix, start, null)
	return

//Checks the end of a string for a specified substring. This proc is case sensitive
//Returns the position of the substring or 0 if it was not found
/proc/dd_hassuffix_case(text, suffix)
	var/start = length(text) - length(suffix)
	if(start)
		return findtextEx(text, suffix, start, null)

/*
 * Text modification
 */
/proc/replace_characters(var/t,var/list/repl_chars)
	for(var/char in repl_chars)
		t = replacetext(t, char, repl_chars[char])
	return t

//Adds 'u' number of zeros ahead of the text 't'
/proc/add_zero(t, u)
	while (length(t) < u)
		t = "0[t]"
	return t

//Adds 'u' number of spaces ahead of the text 't'
/proc/add_lspace(t, u)
	while(length(t) < u)
		t = " [t]"
	return t

//Adds 'u' number of spaces behind the text 't'
/proc/add_tspace(t, u)
	while(length(t) < u)
		t = "[t] "
	return t

//Returns a string with reserved characters and spaces before the first letter removed
/proc/trim_left(text)
	for (var/i = 1 to length(text))
		if (text2ascii(text, i) > 32)
			return copytext(text, i)
	return ""

//Returns a string with reserved characters and spaces after the last letter removed
/proc/trim_right(text)
	for (var/i = length(text), i > 0, i--)
		if (text2ascii(text, i) > 32)
			return copytext(text, 1, i + 1)
	return ""

//Returns a string with reserved characters and spaces before the first word and after the last word removed.
/proc/trim(text)
	return trim_left(trim_right(text))

//Returns a string with the first element of the string capitalized.
/proc/capitalize(var/t as text)
	return uppertext(copytext(t, 1, 2)) + copytext(t, 2)

//Returns a unicode string with the first element of the string capitalized.
/proc/capitalize_utf(var/t as text)
	return uppertext(copytext_char(t, 1, 2)) + copytext_char(t, 2)

//This proc strips html properly, remove < > and all text between
//for complete text sanitizing should be used sanitize()
/proc/strip_html_properly(var/input)
	if(!input)
		return
	var/opentag = 1 //These store the position of < and > respectively.
	var/closetag = 1
	while(1)
		opentag = findtext(input, "<")
		closetag = findtext(input, ">")
		if(closetag && opentag)
			if(closetag < opentag)
				input = copytext(input, (closetag + 1))
			else
				input = copytext(input, 1, opentag) + copytext(input, (closetag + 1))
		else if(closetag || opentag)
			if(opentag)
				input = copytext(input, 1, opentag)
			else
				input = copytext(input, (closetag + 1))
		else
			break

	return input

//This proc fills in all spaces with the "replace" var (* by default) with whatever
//is in the other string at the same spot (assuming it is not a replace char).
//This is used for fingerprints
/proc/stringmerge(var/text,var/compare,replace = "*")
	var/newtext = text
	if(length(text) != length(compare))
		return 0
	for(var/i = 1, i < length(text), i++)
		var/a = copytext(text,i,i+1)
		var/b = copytext(compare,i,i+1)
		//if it isn't both the same letter, or if they are both the replacement character
		//(no way to know what it was supposed to be)
		if(a != b)
			if(a == replace) //if A is the replacement char
				newtext = copytext(newtext,1,i) + b + copytext(newtext, i+1)
			else if(b == replace) //if B is the replacement char
				newtext = copytext(newtext,1,i) + a + copytext(newtext, i+1)
			else //The lists disagree, Uh-oh!
				return 0
	return newtext

//This proc returns the number of chars of the string that is the character
//This is used for detective work to determine fingerprint completion.
/proc/stringpercent(var/text,character = "*")
	if(!text || !character)
		return 0
	var/count = 0
	for(var/i = 1, i <= length(text), i++)
		var/a = copytext(text,i,i+1)
		if(a == character)
			count++
	return count

/proc/reverse_text(var/text = "")
	var/new_text = ""
	for(var/i = length(text); i > 0; i--)
		new_text += copytext(text, i, i+1)
	return new_text

//Used in preferences' SetFlavorText and human's set_flavor verb
//Previews a string of len or less length
/proc/TextPreview(var/string,var/len=40)
	if(length(string) <= len)
		if(!length(string))
			return "\[...\]"
		else
			return string
	else
		return "[copytext_preserve_html(string, 1, 37)]..."

//alternative copytext() for encoded text, doesn't break html entities (&#34; and other)
/proc/copytext_preserve_html(var/text, var/first, var/last)
	return html_encode(copytext(html_decode(text), first, last))

//For generating neat chat tag-images
//The icon var could be local in the proc, but it's a waste of resources
//	to always create it and then throw it out.
/var/icon/text_tag_icons = 'icons/chattags.dmi'
GLOBAL_LIST_EMPTY(text_tag_cache)

/proc/create_text_tag(var/tagname, var/tagdesc = tagname, var/client/C = null)
	if(!(C && C.prefs?.read_preference(/datum/preference/toggle/chat_tags)))
		return tagdesc
	if(!GLOB.text_tag_cache[tagname])
		var/datum/asset/spritesheet_batched/chatassets = get_asset_datum(/datum/asset/spritesheet_batched/chat)
		GLOB.text_tag_cache[tagname] = chatassets.icon_tag(tagname)
	if(!C.tgui_panel.is_ready() || C.tgui_panel.oldchat)
		return "<IMG src='\ref[text_tag_icons]' class='text_tag' iconstate='[tagname]'" + (tagdesc ? " alt='[tagdesc]'" : "") + ">"
	return GLOB.text_tag_cache[tagname]

/proc/create_text_tag_old(var/tagname, var/tagdesc = tagname, var/client/C = null)
	if(!(C && C.prefs?.read_preference(/datum/preference/toggle/chat_tags)))
		return tagdesc
	return "<IMG src='\ref[text_tag_icons]' class='text_tag' iconstate='[tagname]'" + (tagdesc ? " alt='[tagdesc]'" : "") + ">"

/proc/contains_az09(var/input)
	for(var/i=1, i<=length(input), i++)
		var/ascii_char = text2ascii(input,i)
		switch(ascii_char)
			// A  .. Z
			if(65 to 90)			//Uppercase Letters
				return 1
			// a  .. z
			if(97 to 122)			//Lowercase Letters
				return 1

			// 0  .. 9
			if(48 to 57)			//Numbers
				return 1
	return 0

/**
 * Strip out the special beyond characters for \proper and \improper
 * from text that will be sent to the browser.
 */
/proc/strip_improper(var/text)
	return replacetext(replacetext(text, "\proper", ""), "\improper", "")

/proc/pencode2html(t)
	t = replacetext(t, "\n", "<BR>")
	t = replacetext(t, "\[center\]", "<center>")
	t = replacetext(t, "\[/center\]", "</center>")
	t = replacetext(t, "\[br\]", "<BR>")
	t = replacetext(t, "\[b\]", "<B>")
	t = replacetext(t, "\[/b\]", "</B>")
	t = replacetext(t, "\[i\]", "<I>")
	t = replacetext(t, "\[/i\]", "</I>")
	t = replacetext(t, "\[u\]", "<U>")
	t = replacetext(t, "\[/u\]", "</U>")
	t = replacetext(t, "\[time\]", "[stationtime2text()]")
	t = replacetext(t, "\[date\]", "[stationdate2text()]")
	t = replacetext(t, "\[large\]", "<font size=\"4\">")
	t = replacetext(t, "\[/large\]", "</font>")
	t = replacetext(t, "\[field\]", "<span class=\"paper_field\"></span>")
	t = replacetext(t, "\[h1\]", "<H1>")
	t = replacetext(t, "\[/h1\]", "</H1>")
	t = replacetext(t, "\[h2\]", "<H2>")
	t = replacetext(t, "\[/h2\]", "</H2>")
	t = replacetext(t, "\[h3\]", "<H3>")
	t = replacetext(t, "\[/h3\]", "</H3>")
	t = replacetext(t, "\[*\]", "<li>")
	t = replacetext(t, "\[hr\]", "<HR>")
	t = replacetext(t, "\[small\]", "<font size = \"1\">")
	t = replacetext(t, "\[/small\]", "</font>")
	t = replacetext(t, "\[list\]", "<ul>")
	t = replacetext(t, "\[/list\]", "</ul>")
	t = replacetext(t, "\[table\]", "<table border=1 cellspacing=0 cellpadding=3 style='border: 1px solid black;'>")
	t = replacetext(t, "\[/table\]", "</td></tr></table>")
	t = replacetext(t, "\[grid\]", "<table>")
	t = replacetext(t, "\[/grid\]", "</td></tr></table>")
	t = replacetext(t, "\[row\]", "</td><tr>")
	t = replacetext(t, "\[cell\]", "<td>")
	t = replacetext(t, "\[logo\]", "<img src=\ref['html/images/ntlogo.png']")
	t = replacetext(t, "\[redlogo\]", "<img src=\ref['html/images/redntlogo.png']>")
	t = replacetext(t, "\[sglogo\]", "<img src=\ref['html/images/sglogo.png']")
	t = replacetext(t, "\[editorbr\]", "")
	return t

//pencode translation to html for tags exclusive to digital files (currently email, nanoword, report editor fields,
//modular scanner data and txt file printing) and prints from them
/proc/digitalPencode2html(var/text)
	text = replacetext(text, "\[pre\]", "<pre>")
	text = replacetext(text, "\[/pre\]", "</pre>")
	text = replacetext(text, "\[fontred\]", "<font color=\"red\">") //</font> to pass html tag integrity unit test
	text = replacetext(text, "\[fontblue\]", "<font color=\"blue\">")//</font> to pass html tag integrity unit test
	text = replacetext(text, "\[fontgreen\]", "<font color=\"green\">")
	text = replacetext(text, "\[/font\]", "</font>")
	text = replacetext(text, "\[redacted\]", "<span class=\"redacted\">R E D A C T E D</span>")
	return pencode2html(text)

//Will kill most formatting; not recommended.
/proc/html2pencode(t)
	t = replacetext(t, "<pre>", "\[pre\]")
	t = replacetext(t, "</pre>", "\[/pre\]")
	t = replacetext(t, "<font color=\"red\">", "\[fontred\]")//</font> to pass html tag integrity unit test
	t = replacetext(t, "<font color=\"blue\">", "\[fontblue\]")//</font> to pass html tag integrity unit test
	t = replacetext(t, "<font color=\"green\">", "\[fontgreen\]")
	t = replacetext(t, "</font>", "\[/font\]")
	t = replacetext(t, "<BR>", "\[br\]")
	t = replacetext(t, "<br>", "\[br\]")
	t = replacetext(t, "<B>", "\[b\]")
	t = replacetext(t, "</B>", "\[/b\]")
	t = replacetext(t, "<I>", "\[i\]")
	t = replacetext(t, "</I>", "\[/i\]")
	t = replacetext(t, "<U>", "\[u\]")
	t = replacetext(t, "</U>", "\[/u\]")
	t = replacetext(t, "<center>", "\[center\]")
	t = replacetext(t, "</center>", "\[/center\]")
	t = replacetext(t, "<H1>", "\[h1\]")
	t = replacetext(t, "</H1>", "\[/h1\]")
	t = replacetext(t, "<H2>", "\[h2\]")
	t = replacetext(t, "</H2>", "\[/h2\]")
	t = replacetext(t, "<H3>", "\[h3\]")
	t = replacetext(t, "</H3>", "\[/h3\]")
	t = replacetext(t, "<li>", "\[*\]")
	t = replacetext(t, "<HR>", "\[hr\]")
	t = replacetext(t, "<ul>", "\[list\]")
	t = replacetext(t, "</ul>", "\[/list\]")
	t = replacetext(t, "<table>", "\[grid\]")
	t = replacetext(t, "</table>", "\[/grid\]")
	t = replacetext(t, "<tr>", "\[row\]")
	t = replacetext(t, "<td>", "\[cell\]")
	t = replacetext(t, "<img src=\ref['html/images/ntlogo.png']>", "\[logo\]")
	t = replacetext(t, "<img src=\ref['html/images/redntlogo.png']>", "\[redlogo\]")
	t = replacetext(t, "<img src=\ref['html/images/sglogo.png']>", "\[sglogo\]")
	t = replacetext(t, "<span class=\"paper_field\"></span>", "\[field\]")
	t = replacetext(t, "<span class=\"redacted\">R E D A C T E D</span>", "\[redacted\]")
	t = strip_html_properly(t)
	return t

// Random password generator
/proc/GenerateKey()
	//Feel free to move to Helpers.
	var/newKey
	newKey += pick("the", "if", "of", "as", "in", "a", "you", "from", "to", "an", "too", "little", "snow", "dead", "drunk", "rosebud", "duck", "al", "le")
	newKey += pick("diamond", "beer", "mushroom", "assistant", "clown", "captain", "twinkie", "security", "nuke", "small", "big", "escape", "yellow", "gloves", "monkey", "engine", "nuclear", "ai")
	newKey += pick("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
	return newKey

//Used for applying byonds text macros to strings that are loaded at runtime
/proc/apply_text_macros(string)
	var/next_backslash = findtext(string, "\\")
	if(!next_backslash)
		return string

	var/leng = length(string)

	var/next_space = findtext(string, " ", next_backslash + 1)
	if(!next_space)
		next_space = leng - next_backslash

	if(!next_space)	//trailing bs
		return string

	var/base = next_backslash == 1 ? "" : copytext(string, 1, next_backslash)
	var/macro = lowertext(copytext(string, next_backslash + 1, next_space))
	var/rest = next_backslash > leng ? "" : copytext(string, next_space + 1)

	//See http://www.byond.com/docs/ref/info.html#/DM/text/macros
	switch(macro)
		//prefixes/agnostic
		if("the")
			rest = text("\the []", rest)
		if("a")
			rest = text("\a []", rest)
		if("an")
			rest = text("\an []", rest)
		if("proper")
			rest = text("\proper []", rest)
		if("improper")
			rest = text("\improper []", rest)
		if("roman")
			rest = text("\roman []", rest)
		//postfixes
		if("th")
			base = text("[]\th", rest)
		if("s")
			base = text("[]\s", rest)
		if("he")
			base = text("[]\he", rest)
		if("she")
			base = text("[]\she", rest)
		if("his")
			base = text("[]\his", rest)
		if("himself")
			base = text("[]\himself", rest)
		if("herself")
			base = text("[]\herself", rest)
		if("hers")
			base = text("[]\hers", rest)

	. = base
	if(rest)
		. += .(rest)


#define gender2text(gender) capitalize(gender)

/**
 * Used to get a properly sanitized input. Returns null if cancel is pressed.
 *
 * Arguments
 ** user - Target of the input prompt.
 ** message - The text inside of the prompt.
 ** title - The window title of the prompt.
 ** max_length - If you intend to impose a length limit - default is 1024.
 ** no_trim - Prevents the input from being trimmed if you intend to parse newlines or whitespace.
*/
/proc/stripped_input(mob/user, message = "", title = "", default = "", max_length=MAX_MESSAGE_LEN, no_trim=FALSE)
	var/user_input = input(user, message, title, default) as text|null
	if(isnull(user_input)) // User pressed cancel
		return
	if(no_trim)
		return copytext(html_encode(user_input), 1, max_length)
	else
		return trim(html_encode(user_input), max_length) //trim is "outside" because html_encode can expand single symbols into multiple symbols (such as turning < into &lt;)

/**
 * Used to get a properly sanitized input in a larger box. Works very similarly to stripped_input.
 *
 * Arguments
 ** user - Target of the input prompt.
 ** message - The text inside of the prompt.
 ** title - The window title of the prompt.
 ** max_length - If you intend to impose a length limit - default is 1024.
 ** no_trim - Prevents the input from being trimmed if you intend to parse newlines or whitespace.
*/
/proc/stripped_multiline_input(mob/user, message = "", title = "", default = "", max_length=MAX_MESSAGE_LEN, no_trim=FALSE)
	var/user_input = input(user, message, title, default) as message|null
	if(isnull(user_input)) // User pressed cancel
		return
	if(no_trim)
		return copytext(html_encode(user_input), 1, max_length)
	else
		return trim(html_encode(user_input), max_length)

//Adds 'char' ahead of 'text' until there are 'count' characters total
/proc/add_leading(text, count, char = " ")
	text = "[text]"
	var/charcount = count - length_char(text)
	var/list/chars_to_add[max(charcount + 1, 0)]
	return jointext(chars_to_add, char) + text

//Adds 'char' behind 'text' until there are 'count' characters total
/proc/add_trailing(text, count, char = " ")
	text = "[text]"
	var/charcount = count - length_char(text)
	var/list/chars_to_add[max(charcount + 1, 0)]
	return text + jointext(chars_to_add, char)

//Readds quotes and apostrophes to HTML-encoded strings
/proc/readd_quotes(var/t)
	var/list/repl_chars = list("&#34;" = "\"","&#39;" = "'")
	for(var/char in repl_chars)
		var/index = findtext(t, char)
		while(index)
			t = copytext(t, 1, index) + repl_chars[char] + copytext(t, index+5)
			index = findtext(t, char)
	return t

// Rips out paper HTML but tries to keep it semi-readable.
/proc/paper_html_to_plaintext(paper_text)
	paper_text = replacetext(paper_text, "<hr>", "-----")
	paper_text = replacetext(paper_text, "<li>", "- ") // This makes ordered lists turn into unordered but fixing that is too much effort.
	paper_text = replacetext(paper_text, "</li>", "\n")
	paper_text = replacetext(paper_text, "<p>", "\n")
	paper_text = replacetext(paper_text, "<br>", "\n")
	paper_text = strip_html_properly(paper_text) // Get rid of everything else entirely.
	return paper_text

//json decode that will return null on parse error instead of runtiming.
/proc/safe_json_decode(data)
	try
		return json_decode(data)
	catch
		return null

/// Removes all non-alphanumerics from the text, keep in mind this can lead to id conflicts
/proc/sanitize_css_class_name(name)
	var/static/regex/regex = new(@"[^a-zA-Z0-9]","g")
	return replacetext(name, regex, "")

/// Returns TRUE if the input_text ends with the ending
/proc/endswith(input_text, ending)
	var/input_length = LAZYLEN(ending)
	return !!findtext(input_text, ending, -input_length)

/// Returns TRUE if the input_text starts with any of the beginnings
/proc/starts_with_any(input_text, list/beginnings)
	for(var/beginning in beginnings)
		if(!!findtext(input_text, beginning, 1, LAZYLEN(beginning)+1))
			return TRUE
	return FALSE

//finds the first occurrence of one of the characters from needles argument inside haystack
//it may appear this can be optimised, but it really can't. findtext() is so much faster than anything you can do in byondcode.
//stupid byond :(
/proc/findchar(haystack, needles, start=1, end=0)
	var/temp
	var/len = length(needles)
	for(var/i=1, i<=len, i++)
		temp = findtextEx(haystack, ascii2text(text2ascii(needles,i)), start, end)	//Note: ascii2text(text2ascii) is faster than copytext()
		if(temp)	end = temp
	return end
