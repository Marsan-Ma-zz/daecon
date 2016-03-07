# coding: utf-8

require 'mongoid'
require 'mongoid_auto_increment_id'

Mongoid.load!("mongoid.yml")

module Mongoid
  module BaseModel
    extend ActiveSupport::Concern
    included do
      include Mongoid::Document
      include Mongoid::Timestamps
      scope :order_updated, desc(:updated_at)
      scope :recent, desc(:_id)
      before_save :stop_redundent_save
      def stop_redundent_save
        return false if not self.changed?
      end
    end
  end
end

class User
  include Mongoid::BaseModel

  field :uuid
  index :uuid => 1

  has_many :views
  has_many :interests
end

class Interest
  include Mongoid::BaseModel
  
  field :word
  field :count, :type => Integer, :default => 0

  index :word => 1
  index :count => 1

  belongs_to :user, index: true
end

class View
  include Mongoid::BaseModel

  field :host
  field :count, :type => Integer, :default => 0

  index :host => 1
  index :count => 1

  belongs_to :user, index: true
  belongs_to :page, index: true
end

class Page
  include Mongoid::BaseModel

  field :host
  field :url
  field :title
  field :thumb
  field :public, :type => Boolean, :default => true
  field :count, :type => Integer, :default => 0
  field :cast, :type => Integer, :default => 0
  field :accept, :type => Integer, :default => 0
  field :words, :type => Array, :default => []

  index :host => 1
  index :url => 1
  index :public => 1
  index :count => 1
  index :cast => 1
  index :accept => 1

  has_many :views
  scope :chosen, desc(:count).limit(25)
end

