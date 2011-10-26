Photostat
=========

For managing photos, like a hacker.

Here's what this app currently does:

* it builds a local repository of photos organized in $REPO/$Y-$m directories
* it takes care of duplicates (the file's identity is based on an MD5 hash, not on the file's name)
* files are renamed based on creation date / hash, so it prevents you from accidental overwritting
* the creation date is taken from the file's EXIF data
* can start a local web interface for viewing the files as a continuous stream (it has an embedded server, serving a web app, clean interface, navigation is done with shortcuts)
* in the web interface I need thumbnails, which are best generated from the command-line

What I also want it to do:

* the web interface must be able to edit tags / visibility / title / description
* the web interface must be able to filter on creation date / tags / visibility
* synchronize with Flickr/Picassa, also exporting tags / visibility / title / description
* on synchronization with Flickr/Picassa, I do not want to reupload
  the same files multiple times (this logic is already done for Flickr
  by recording the MD5 in a machine tag, see in junk/)

Rationale
---------

I'm tired of graphical UIs that suck.

I tried using Google's Picassa, and one thing that bugs me is that the
organization of photos is hard work. This software expects you to drop
your photos in a sub-directory somewhere and then it indexes it,
remembering where it is and so on. However, the problem with this
approach is that the photos end-up being stored in a sub-directory
structure of your own, scattered all over the place, ending up being a
mess. Or you just drop your photos in a big directory, which creates
the potential for older photos being overwritten (the incompetent that
took pictures at my wedding actually did this).

I tried using the F-Spot photo manager, and it is pretty good as it
takes care of this organization for you. When you import photos, it
has its own logical directory structure, something like
$YEAR/$MONTH/$NAME. On the other hand it had quirks when I used it,
for example it wasn't taking care of duplicates, which is an easy task
and quite important, since when you have a big photo collection you
also end-up with a lot of junk. 

I also like the idea of having a backup in the cloud, on services like
Flickr / Google's Picassa. But uploading files using the tools I tried
is such a pain that it isn't even funny.

Available tools don't check to see if the file is already
there. Uploading itself is a manual process (selecting files you want
to upload, then hit upload). I don't want plain upload. I want
periodic synchronization instead.

So in the spirit of doing it with your own hand (since that's the best
approach when something hurts), I'm doing it myself.
