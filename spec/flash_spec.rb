require 'backports'
require_relative 'spec_helper'

class BaseApp < Sinatra::Base
  enable :sessions
  register Sinatra::Flash
  
  get '/dummy' do
    "This page does not invoke the flash at all."
  end

  get '/flash' do
    if params[:key]
      flash(params[:key]).inspect
    else
      flash.inspect
    end
  end

  post '/flash' do
    if (key = params.delete('key'))
      params.each{|k,v| flash(key)[k.to_sym] = v.to_sym}
      flash(key).inspect
    else
      params.each{|k,v| flash[k.to_sym] = v.to_sym}
      flash.inspect
    end
  end
end

describe Sinatra::Flash do
  def app
    BaseApp
  end

  before(:each) do
    Sinatra::TestHelpers.session = { 
        :flash => {:marco => :polo},
        :smash => {:applecore => :baltimore}}    
  end
      
  it "provides a 'flash' helper" do
    get '/flash'
    last_response.body.should =~ /\{.*\}/
  end
  
  it "looks up the :flash variable in the session by default" do
    get '/flash'
    last_response.body.should == "{:marco=>:polo}"
  end
  
  it "is empty, not nil, if there's no session" do
    Sinatra::TestHelpers.session = nil
    get '/flash'
    last_response.body.should == "{}"
  end

  it "can take a different flash key" do
    get '/flash', {:key => :smash}
    last_response.body.should == "{:applecore=>:baltimore}"
  end
  
  it "is empty, not nil, if the session doesn't have the flash key" do
    get '/flash', {:key => :trash}
    last_response.body.should == "{}"
  end
  
  it "can set the flash for the future" do
    post '/flash', {:fire => :ice}
    last_response.body.should == "{:marco=>:polo}"
  end

  it "knows the future flash" do
    post '/flash', {:fire => :ice}
    get '/flash'
    last_response.body.should == "{:fire=>:ice}"
  end
  
  it "can set a different flash key for the future" do
    post '/flash', {:key => :smash, :knockknock => :whosthere}
    get '/flash', {:key => :smash}
    last_response.body.should == "{:knockknock=>:whosthere}"
  end
  
  it "sweeps only the flash that gets used" do
    post '/flash', {:hi => :ho}
    post '/flash', {:aweem => :owep, :key => :smash}
    get '/flash', {:key => :smash}
    last_response.body.should == "{:aweem=>:owep}"
    get '/flash'
    last_response.body.should == "{:hi=>:ho}"
  end
  
  it "behaves well when nothing ever checks the flash" do
    get '/dummy'
    last_response.body.should == "This page does not invoke the flash at all."
  end
end
