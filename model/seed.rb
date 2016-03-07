#!/usr/bin/env ruby -I ../lib -I lib
# coding: utf-8

require 'cgi'

#====================================
#   seed data from files
#====================================
def db_seeds(sample_max=-1)
  users, pages, views = db_seeds_upv_hash(sample_max)
  pages = db_seeds_upv_record(users, pages, views)
  db_interests(pages, views)
  report_all
  puts "Finish ~"
end 

def db_seeds_upv_hash(sample_max=-1)
  # page titles
  actions   = file2hash('./model/seed/active.json', 'ac_id', 'ac_name')   # babyshop {ac_id, ac_name, p_id, c_id}
  images    = file2hash('./model/seed/active.json', 'ac_id', 'ac_pic')   # babyshop {ac_id, ac_name, p_id, c_id}
  product   = file2hash('./model/seed/product.json', 'p_id', 'p_name')    # order {p_id, p_name}
  comments  = file2hash('./model/seed/comments.json', 'c_id', 'c_title')  # order {c_id, p_id, c_title}

  # pageviews
  #preprocess_mamibuy('./model/seed/pageview.csv', './model/seed/pageview.clr')
  f = File.open('./model/seed/pageview.clr')
  sample_num = 0
  time_start = Time.now

  # database in ram
  users = Hash.new { |h, k| h[k] = Hash.new }
  pages = Hash.new { |h, k| h[k] = Hash.new }
  views = Hash.new { |h, k| h[k] = Hash.new }

  f.each_line do |line|
    sample_num += 1
    break if (sample_num == sample_max)
    begin
      puts "[UPV Hash] " + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 50000 == 0)
      name, uuid, count, url = line.split(',')
      host, path, title, thumb  = parseURL(url, actions, images, comments)
      if (title && (title != "")) # new product not in database
        users[uuid] = {"uuid"=>uuid} if (users[uuid] == {})
        pkey = host + '/' + title.strip
        if (pages[pkey] == {})
          pages[pkey] = {"host"=>host, "url"=>purify_url(url), "title"=>title, "thumb"=>thumb, "public"=>get_shown(host, url), "count"=>1}
        else
          pages[pkey]["url"] = purify_url(url) if (purify_url(url).length < pages[pkey]["url"].length)
          pages[pkey]["count"] += 1
        end
        vkey = uuid + '/' + pkey
        if (views[vkey] == {})
          views[vkey] = {"host"=>host, "user_key"=>uuid, "page_key"=>pkey, "count"=>1}
        else
          views[vkey]["count"] += 1
        end
      end
    rescue Exception => e
      puts line
      puts e.to_s
      puts e.backtrace
      next
    end
  end
  return users, pages, views
end

def db_seeds_upv_record(users, pages, views)
  # User
  sample_num = 0
  time_start = Time.now
  users.each do |i|
    sample_num += 1
    puts "[User record] " + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 5000 == 0)
    j = i[1]
    u = User.create(:uuid => j["uuid"])
    users[i[0]]["id"] = u.id
  end

  # Page
  sample_num = 0
  time_start = Time.now
  pages.each do |i|
    sample_num += 1
    puts "[Page record] " + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 5000 == 0)
    j = i[1]
    title = j["host"] == 'mamibuy' ? j["title"].gsub(/[a-zA-Z]/, ' ') : j["title"]
    words = str2words(title)
    k = Page.create(:host => j["host"], :url => j["url"], :title => j["title"], :thumb => j["thumb"], 
                    :public => j["public"], :count => j["count"], :words => words )
    pages[i[0]]["id"] = k.id
    pages[i[0]]["words"] = words
  end

  # View
  sample_num = 0
  time_start = Time.now
  views.each do |i|
    sample_num += 1
    puts "[View record] " + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 1000 == 0)
    j = i[1]
    vuser_id = users[j["user_key"]]["id"]
    vpage_id = pages[j["page_key"]]["id"]
    k = View.create(:host => j["host"], :user_id => vuser_id, :page_id => vpage_id, :count=>j["count"])
    views[i[0]]["id"] = k.id
    views[i[0]]["user_id"] = k.user_id
    views[i[0]]["page_id"] = k.page_id
    views[i[0]]["words"] = pages[j["page_key"]]["words"]
  end
  return pages
end

def db_interests(pages, views)
  # Interest Hash
  sample_num = 0
  time_start = Time.now
  fints = Hash.new { |h, k| h[k] = Hash.new(0) }
  views.each do |i|
    sample_num += 1
    puts "[Interest Hash] " + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 50000 == 0)
    page_id = i[1]["page_id"]
    user_id = i[1]["user_id"]
    words   = i[1]["words"]
    words.each do |w|
      fints[user_id][w] += i[1]["count"]
    end
  end
  # Interest record
  sample_num = 0
  time_start = Time.now
  fints.each do |user|
    user[1].each do |word|
      sample_num += 1
      puts "[Interest record]" + (Time.now - time_start).round(2).to_s + "sec, sample num = " + sample_num.to_s if (sample_num % 1000 == 0)
      Interest.create(:word => word[0], :count => word[1], :user_id => user[0])
    end
  end
end

#====================================
#   Tasks
#====================================
def parseURL(url, actions, images, comments)
  host = 'mamibuy'
  path = url.split('/')[3]
  params = CGI::parse(path)
  case path.scan(/(.*)\?/)[0][0]
    when "babyshop"
      title = actions[params["acid"][0].to_i]
      thumb = 'http://mamibuy.com.tw/' + images[params["acid"][0].to_i]
    when "order"
      title = actions[params["acid"][0].to_i]
      thumb = nil
    when "news"
      title = comments[params["cid"][0].to_i]
      thumb = nil
  end
  return host, path, title, thumb
end

def file2hash(filename, key, value)
  items = Hash.new("")
  json = File.read(filename)
  JSON.parse(json).each do |j|
    begin
      items[j[key]] = j[value] 
    rescue 
      puts j
      break
    end
  end
  items
end

def preprocess_mamibuy(fin, fout)
  subStr = [['https', 'http'], ['www.mamibuy.com.tw', 'mamibuy.com.tw'], ['.php', ''], 
            ['46.137.242.185', 'mamibuy.com.tw'], ['ec2-46-137-242-185.ap-southeast-1.compute.amazonaws.com', 'mamibuy.com.tw']]
  open(fout, 'w') do |f|
    File.open(fin).each_line do |line|
      subStr.each do |i|
        line = line[line.index(',')..-1].gsub(i[0], i[1])
      end
      f.puts line
    end
  end
end

#====================================
#   for debug only
#====================================
def report_all
  puts '[User]: ' + User.count.to_s
  puts '[Page]: ' + Page.count.to_s
  puts '[View]: ' + View.count.to_s
  puts '[Interest]:  ' + Interest.count.to_s
end

def delete_all
  User.each{|u| u.destroy}
  Page.each{|u| u.destroy}
  View.each{|u| u.destroy}
  Interest.each{|u|  u.destroy}
end

def create_indexes
  User.create_indexes
  Page.create_indexes
  View.create_indexes
  Interest.create_indexes
end
 
def db_reset
  delete_all
  create_indexes
  report_all
end

