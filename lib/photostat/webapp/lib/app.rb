DB = Photostat::DB.instance

def photos_with_thumbs
  # only select photos with thumbnails available
  config = Photostat.config
  repo = config[:repository_path]

  return DB[:photos].order(:created_at).reverse.all.select do |photo|
    File.exists? File.join(repo, 'system', 'thumbs', '200', photo[:local_path])
  end
end

get '/' do
  @photos = photos_with_thumbs
  erb :'photos/list'
end

get '/:id/' do
  @photo = DB[:photos].where(:id => params[:id]).first
  erb :'photos/view'
end

get '/:id/prev/' do
  curr = -1
  id = params[:id].to_i

  photos = photos_with_thumbs
  photos.each_index do |idx|
    if id == photos[idx][:id]
      curr = idx
      break
    end
  end

  curr -= 1
  curr = photos.length - 1 if curr - 1 < 0 
  redirect '/' + photos[curr][:id].to_s + '/'
end

get '/:id/next/' do
  curr = -1
  id = params[:id].to_i

  photos = photos_with_thumbs
  photos.each_index do |idx|
    if id == photos[idx][:id]
      curr = idx
      break
    end
  end

  curr += 1
  curr = 0 if curr + 1 >= photos.length
  redirect '/' + photos[curr][:id].to_s + '/'
end
