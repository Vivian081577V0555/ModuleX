customize = ViewCustomize.find(3)
customize.update!(code: File.read('/tmp/modulex_home-v2.js'))
Setting.ui_theme = 'modulex_nexus'

puts "customize_id=#{customize.id}"
puts "customize_bytes=#{customize.code.bytesize}"
puts "active_theme=#{Setting.ui_theme}"
