Place the five approved MP4 reel videos in this directory to bundle them with
Career Connect. The app discovers these videos automatically and plays them
without the server or Cloudinary. Use filenames ordered 01 through 05 to control
their order. Rebuild the app after adding assets.

Videos added using Add video are copied into the app's private documents folder.
They persist across restarts, are only visible on that device, and are removed
when the app's data is cleared or the app is uninstalled. Signed-in uploads are
queued for the current account and retried every 30 seconds while the reels
screen is open in the foreground. The existing authenticated server API uploads
to Cloudinary and records the reel in its configured database. Closed-app
background synchronization is not implemented. Uploads must satisfy the server's
60-second limit. A lost server response can cause a duplicate on retry.
