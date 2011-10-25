DB = Photostat::DB.instance

get '/' do
  @photos = DB[:photos]
  erb :'photos/list'
end

