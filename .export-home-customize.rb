customize = ViewCustomize.find(3)
File.write('/tmp/view_customize_3_original.js', customize.code)
puts "id=#{customize.id}"
puts "path_pattern=#{customize.path_pattern}"
puts "type=#{customize.customize_type}"
puts "enabled=#{customize.is_enabled}"
puts "code_bytes=#{customize.code.bytesize}"
