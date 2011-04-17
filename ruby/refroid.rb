require 'pstore'
exit if ARGV.empty?
class_name, current_apilevel = ARGV
current_apilevel ||= 1000
current_apilevel = current_apilevel.to_i
table = PStore.new("#{ENV['HOME']}/.vim/ruby/refroid.db").transaction{|db| db[:table] }
candidates = table[class_name] || table.select{|k,v| k.start_with?(class_name) }.inject([]){|l, r| l + r[1] }
exit if candidates.size > 9
filtered = candidates.select{|display_name, namespaces, qualified_name, apilevel| apilevel <= current_apilevel }

puts filtered.map{|display_name, namespaces, qualified_name, apilevel| "#{display_name} #{namespaces.join('/')} #{qualified_name} #{apilevel}" }

