
# We're "vendoring" the rhosync/lib directory here so we can use the working copy of
# rhosync.  Normally, you would require rhosync as a gem or vendor it here.
path = File.join(File.dirname(__FILE__),'..','..','..','..','..','lib')
$:.unshift path
require File.join(path,'rhosync')