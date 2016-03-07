#!/usr/bin/env ruby -I ../lib -I lib
# coding: utf-8
require 'sinatra'
require 'sinatra/contrib/all'
require 'json'
require './model/schema.rb'

helpers do
  def partial (template, locals = {})
    erb(template, :layout => false, :locals => locals)
  end
end

configure :development do
  ENV["SINA_ENV"] = "development"
end

#====================================
#   Test
#====================================
get '/test' do
  @users = User.order_updated.limit(10)
  @pages = Page.order_updated.limit(10)
  @views = View.order_updated.limit(10)
  erb :probe
end

get '/user/:uuid' do
  @users = User.where(:uuid => params[:uuid]).limit(10)
  user_ids = @users.only(:id).map(&:id)
  @views = View.where(:user_id.in => user_ids).limit(10)
  erb :probe
end

get '/page/:id' do
  @pages = Page.where(:id.in => [params[:id]]).limit(10)
  views = @pages.first.views.limit(10)
  user_ids = views.only(:user_id).map(&:user_id)
  @users = User.where(:id.in => user_ids).limit(10)
  erb :probe
end

#====================================
#   Demo
#====================================
get '/demo' do
  erb :demo
end

#====================================
#   Host
#====================================
get '/:host/probe' do
  @pages = Page.where(:host => params[:host]).desc(:accept).limit(10)
  views = View.where(:host => params[:host]).order_updated.limit(10)
  user_ids = views.only(:user_id).map(&:user_id)
  @users = User.where(:id.in => user_ids).order_updated.limit(10)
  erb :probe
end

get '/:host/suggest' do
  cookies[:uuid] = nil if (params[:clean] == "true")
  if params[:page]
    @page = Page.where(:host => params[:host], :id => params[:page]).first
  else
    page_ids = Page.where(:public => true).order_updated.only(:id).limit(100).map(&:id)
    @page = Page.where(:host => params[:host], :id => page_ids[rand(page_ids.count)]).first
  end
  if check_nil(cookies[:uuid])
    user = get_user(cookies[:uuid])
    page_ids = View.where(:host => params[:host], :user_id => user.id).only(:page_id).map(&:page_id).uniq
    @history = Page.where(:id.in => page_ids).order_updated.limit(15)
  end
  erb :suggest
end

get '/api/test/mamibuy' do
  redirect '/mamibuy/suggest'
end

#====================================
#   API
#====================================
get '/api/pageview' do
  if (params[:host] && params[:target])
    user, page = process_pageview(params)
    response = get_response(page, user, params)
  else
    response = {"status" => "error"}
  end
  # jsonp response
  content_type :js
  callback = params.delete('callback')
  resp = "#{callback}(#{response.to_json})"
end

get '/api/accept' do
  puts "[PARAMS]" + params.to_s
  page = Page.where(:host => params[:host], :url => params[:target]).first
  page.update_attribute(:accept, page.accept+1) if page
  response = {"status" => "ok"}
  puts page.to_json
  # jsonp response
  content_type :js
  callback = params.delete('callback')
  resp = "#{callback}(#{response.to_json})"
end

#====================================
#   Basic tasks
#====================================
get '/*' do
  erb :demo
end
 
private 

require './model/upk.rb'      # User/Page/Key related
require './model/seed.rb'     # seed data functions

