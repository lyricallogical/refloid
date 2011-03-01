require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'pstore'

CLASS_REFERENCE_URL = 'http://developer.android.com/reference/classes.html'
CLASS_PATH = "td.jd-linkcol"

page = Nokogiri::HTML(open(CLASS_REFERENCE_URL, "User-Agent" => "Ruby/#{RUBY_VERSION}"))

classes = page.css(CLASS_PATH).map do |td|
  a, _ = td.css('a')
  tr = td.parent
  tr_classes = tr['class'].split
  # /reference/xxx/yyy/Zzz.html
  href = a['href']

  # "outer.inner"
  qualified_name = a.text
  # "inner"
  class_name = qualified_name.split('.').last
  # ["xxx", "yyy"]
  namespaces = href.split("/")[2..-2]
  # R.stylable だけ apilevel がない("apilevel-" )ので + でなく *
  apilevel = tr_classes.grep(/^apilevel-(\d*)$/){ $1.to_i }.first

  [qualified_name, class_name, namespaces, apilevel]
end

# qualified_name の同じクラスがある場合には、区別できるよう名前空間も含めたものを表示名に
# ない場合には qualified_name を表示名に
# e.g. Annotation
qualified_names = classes.map(&:first)
classes.map! do |qualified_name, class_name, namespaces, apilevel|
  display_name = qualified_names.count(qualified_name) > 1 ? (namespaces + [qualified_name]).join('.') : qualified_name
  [qualified_name, class_name, display_name, namespaces, apilevel]
end

table = Hash.new
classes.each do |qualified_name, class_name, display_name, namespaces, apilevel|
  table[class_name] = [] if !table.has_key?(class_name)
  table[class_name] << [display_name, namespaces, qualified_name, apilevel]
end

table.each do |class_name, candidates|
  table[class_name] = candidates.sort
end

db = PStore.new('refroid.db')
db.transaction {
  db[:table] = table
  db[:table_type] = { :key => :class_name, :value => [[:display_name, [:namespaces], :qualified_name, :apilevel]]}
}

