#! /c/ruby/bin/ruby

require 'net/http'
require 'uri'

readme_file = "README.textile"
unless File.exists?(readme_file)
	puts "No README.textile file!"
	exit 1
end
readme = File.read(readme_file)


git_file = ".git/config"
unless File.exists?(git_file)
	puts "Not a git repo!"
	exit 1
end
github_project = "http://github.com/tekkub/#{$1}/tree/master" if File.read(git_file) =~ /git@github.com:tekkub\/(.+).git/
unless github_project
	puts "Cannot find github project"
	exit 1
end
res = Net::HTTP.get(URI.parse(github_project))
pledgie_url, pledgie_img = $1, $2 if res =~ /<a href='([^']+)'><img alt='[^']+' src='([^']+)'/
unless pledgie_url and pledgie_img
	puts "Cannot find pledgie url"
	exit 1
end

[ # Purge single newlines
	[/<br\s?\/?>/, 'BREAKTOKEN'],
	[/([^\n])\n([^\n#*])/, '\1 \2'],
	[/BREAKTOKEN\s?/, "\n"],
].each {|pair| readme.gsub!(pair[0], pair[1])}


LISTS_RE = /^(([#*]+[^\n]*)\n)+$/m
LISTS_CONTENT_RE = /^([#*]+) (.*)$/m

readme.gsub!( LISTS_RE ) do |match|
	lines = match.split( /\n/ )
	last_line = -1
	depth = []
	lines.each_index do |line_id|
		if lines[line_id] =~ LISTS_CONTENT_RE
			tl,content = $~[1..2]
			if depth.last
				if depth.last.length > tl.length
					(depth.length - 1).downto(0) do |i|
						break if depth[i].length == tl.length
						lines[line_id - 1] << "\n[/LIST]"
						depth.pop
					end
				end
			end
			unless depth.last == tl
				depth << tl
				lines[line_id] = "[LIST#{tl =~ /\#$/ ? '=1' : ''}]\n[*]#{content}"
			else
				lines[line_id] = "[*]#{content}"
			end
			last_line = line_id

		else
			last_line = line_id
		end
		if line_id - last_line > 1 or line_id == lines.length - 1
			depth.delete_if do |v|
				lines[last_line] << "\n[/LIST]"
			end
		end
	end
	lines.join( "\n" )
end


github = "Alpha builds can be found on [url=#{github_project}]github[/url].\n"
pledgie = "\n\n[URL='#{pledgie_url}'][IMG]#{pledgie_img}[/IMG][/URL]"
[
	[/<b>(Visit .* mailinglist).?<\/b>/m, '[SIZE=2][B][COLOR=SandyBrown]\1[/COLOR][/B][/SIZE]'],
	[/<p\s?[^>]*>/, ''],
	["</p>", ''],
	[/<div\s?[^>]*>/, ''],
	["</div>", ''],
	[/<a href="([^"]*)(.*)<\/a>">/, '[URL=\1]\2[/URL]'],
	[/"([^"]+)":(http:\/\/\S+)/, '[URL=\2]\1[/URL]'],
	[/<code>(.*)<\/code>/, '[COLOR="Teal"]\1[/COLOR]'],
	[/@(.*)@/, '[COLOR="Teal"]\1[/COLOR]'],
	[/h2\. (.*)/, '[size=3][b]\1[/b][/size]'],
	[/<b>(.*)<\/b>/, '[B]\1[/B]'],
	#~ [/\*([^*]*)\*/, '[B]\1[/B]'],
	[/<em>(.*)<\/em>/, '[I]\1[/I]'],
	[/<i>(.*)<\/i>/, '[I]\1[/I]'],
	#~ [/_([^_]*)_/, '[I]\1[/I]'],
	[/<u>(.*)<\/u>/, '[U]\1[/U]'],
	[/(Please direct all feedback .*)/, github + '\1' + pledgie],
	[/\n\n+\s?/, "\n\n"]
].each {|pair| readme.gsub!(pair[0], pair[1])}


puts readme
