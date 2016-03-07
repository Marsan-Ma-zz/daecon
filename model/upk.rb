#!/usr/bin/env ruby -I ../lib -I lib
# coding: utf-8

require 'rmmseg'

RMMSeg::Dictionary.dictionaries = [[:chars, "./model/dic/chars.dic"], [:words, "./model/dic/words.dic"]]
RMMSeg::Dictionary.load_dictionaries

#====================================
#   Main
#====================================
def process_pageview(params)
  user = get_user(params[:uuid])
  page = get_page(params[:host], params[:target], params[:title], params[:thumb], params[:shown], user)
  view = get_view(params[:host], page.id, user.id)
  return user, page
end

def get_response(page, user, params)
  resp = Hash.new("")
  resp["pvuid"] = user.uuid
  resp["funcen"] = params[:func]
  ex_page = Page.where(:id => page.id)
  if check_nil(params[:func])
    if (params[:func][0] == '1')
      pkp = pkp(params[:host], page)
      resp["pkp"] = page_output(pkp, ex_page)
    end
    if (params[:func][1] == '1')
      pup = pup(params[:host], page)
      resp["pup"] = page_output(pup, ex_page)
    end
    if (params[:func][2] == '1')
      ukp = ukp(params[:host], user)
      resp["ukp"] = page_output(ukp, ex_page)
    end
    if (params[:func][3] == '1')
      ugp = ugp(params[:host], user)
      resp["ugp"] = page_output(ugp, ex_page)
    end
    if (params[:func] == '11111')
      pkp_ids = pkp.only(:id).map(&:id)
      pup_ids = pup.only(:id).map(&:id)
      ukp_ids = ukp.only(:id).map(&:id)
      ugp_ids = ugp.only(:id).map(&:id)
      all_ids = pkp_ids.concat(pup_ids).concat(ukp_ids).concat(ugp_ids).uniq
      resp["all"] = page_output(Page.where(:id.in => all_ids).chosen, ex_page)
    end
  end
  #puts resp.to_json
  resp
end

def page_output(pages, ex_page)
  pages -= ex_page
  pages.to_json
end

#-------------------------------------
def pkp(host, page)
  pages = w2p(host, page.words)
end

def pup(host, page)
  user_ids = p2u(host, page.views)
  pages = u2p(host, user_ids)
end

def ukp(host, user)
  words = i2w(host, user.interests)
  pages = w2p(host, words)
end

def ugp(host, user)
  words = i2w(host, user.interests)
  user_ids = w2u(host, words)
  pages = u2p(host, user_ids)
end

#-------------------------------------
def p2u(host, views)
  user_ids = views.where(:host => host).desc(:count).limit(20).only(:user_id).map(&:user_id).uniq
end

def i2w(host, interests)
  words = interests.desc(:count).limit(20).only(:word).map(&:word).uniq
end

def w2u(host, words)
  user_ids = Interest.where(:word.in => words).desc(:count).limit(20).only(:user_id).map(&:user_id).uniq
end

#-------------------------------------
def w2p(host, words)
  pages = Page.where(:host => host, :words.in => words, :public => true).chosen
  incr_case(pages)
  pages
end

def u2p(host, user_ids)
  page_ids  = View.where(:host => host, :user_id.in => user_ids).desc(:count).limit(20).only(:page_id).map(&:page_id).uniq
  pages = Page.where(:id.in => page_ids, :public => true).chosen
  incr_case(pages)
  pages
end

def incr_case(pages)
  pages.each do |i|
    i.update_attribute(:cast, i.cast + 1)
  end
end
#====================================
#   User
#====================================
# for local test
def get_user(uuid, local=false)
  if local
    uuid = check_nil(uuid) ? uuid : SecureRandom.uuid
  else
    uuid = check_nil(cookies[:uuid]) ? cookies[:uuid] : check_nil(uuid) ? uuid : SecureRandom.uuid
    cookies[:uuid] = uuid
  end
  user = User.where(:uuid => uuid).first
  user = User.new(:uuid => uuid) if not user
  user.save
  return user
end

#====================================
#   Page
#====================================
def get_page(host, url, title, thumb, shown, user)
  url  = purify_url(url)
  page = Page.where(:host => host, :title => title).first
  page = Page.create(:host => host, :title => title) if not page
  page.url = url if (page.url.nil? || (page.url.length > url.length))
  page.public = (shown == 'false') ? false : true
  page.host = host if host
  page.thumb = thumb if thumb
  page.count += 1
  page.words = str2words(title) if page.words.empty?
  page.save
  return page
end

def get_view(host, page_id, user_id)
  view = View.where(:host => host, :page_id => page_id, :user_id => user_id).first
  view = View.new(:host => host, :page_id => page_id, :user_id => user_id) if not view
  view.count += 1
  view.save
  view.page.words.each do |w|
    int = Interest.where(:user_id => user_id, :word => w).first
    int = Interest.create(:user_id => user_id, :word => w) if not int
    int.update_attribute(:count, int.count+1)
  end
  return view
end

#====================================
#   String process
#====================================
def check_nil(str)
  null_str = ['nil', 'null', 'undefined']
  (str.nil? || str.empty? || null_str.include?(str)) ? nil : str
end

def purify_url(url)
  url.split('/')[3..-1].join('/').gsub(/#.*\n/, '').gsub('.php', '').strip
end

def get_shown(host, url)
  case host
    when "mamibuy"
      shown = url.include?('babyshop') ? true : false
    else
      shown = true
  end
end

def str2words(str)
  rmm = RMMSeg::Algorithm.new(str)
  words = []
  loop do
    tok = rmm.next_token
    break if tok.nil?
    txt = tok.text.force_encoding('UTF-8')
    if ((txt =~ /[\p{Han}[a-z]]/) && (txt.size > 1))
      words << txt if not words.include?(txt)
    end
  end
  words
end


