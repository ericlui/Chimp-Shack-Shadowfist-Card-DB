# encoding: utf-8

ARGF.each do |line|
  line = line.force_encoding('IBM437').encode('UTF-8')
  line.gsub!(/[\“\”]/, '"')
  # 2565, 2559 are the munged smart quotes
  line.gsub!(/[\u201C\u201d\u2565\u2559]/, '"')
  # 2552 is the munged apostrophe
  line.gsub!(/[\u00ef\u00bf\u00bd\u2552]/u, "'")
  line.gsub!(/\r\n?/, "\n")
  puts line
end
