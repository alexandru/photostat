Photostat
=========

For managing photos, like a hacker. It is already usable for me, but
work is still in progress and I don't recommend it to people yet.

Here's what this app currently does:

* it builds a local repository of photos organized in $REPO/$Y-$m directories
* movies (MOV) are copied in $REPO/movies
* it takes care of duplicates (the file's identity is based on an MD5 hash + the created date)
* the creation date is taken from the file's EXIF data
* in case of movies, it is the date of the last modification
* on flickr:sync it uploads missing files from local repo to Flickr
  (takes care of duplicates) and also downloads tags / visibility info


Rationale
---------

I'm tired of graphical UIs that suck.

I also need consistent backup in the cloud.
Now I'm working on Flickr integration, Picasa coming next.

I want 2 cheap cloud backups and a properly managed local repository.
These photos are too important for me.