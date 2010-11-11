require 'fileutils'
require 'digest/md5'

module MCollective
    module Agent
        class Filemgr<RPC::Agent
            metadata    :name        => "filemgr",
                        :description => "File Manager",
                        :author      => "Mike Pountney <mike.pountney@gmail.com>",
                        :license     => "Apache 2",
                        :version     => "0.3",
                        :url         => "http://www.puppetlabs.com/mcollective",
                        :timeout     => 5

            # Basic file touch action - create (empty) file if it doesn't exist,
            # update last mod time otherwise.
            # useful for checking if mcollective is operational, via NRPE or similar.
            action "touch" do
                touch
            end

            # Basic file removal action
            action "remove" do
                remove
            end

            # Basic status of a file
            action "status" do
                status
            end

            private
            def get_filename
                request[:file] || config.pluginconf["filemgr.touch_file"] || "/var/run/mcollective.plugin.filemgr.touch"
            end

            def status
                file = get_filename
                reply[:output] = "not present"
                reply[:present] = 0
                reply[:size] = 0
                reply[:type] = "unknown"
                reply[:mode] = "0000"
                reply[:mtime] = 0
                reply[:ctime] = 0
                reply[:atime] = 0
                reply[:mtime_seconds] = 0
                reply[:ctime_seconds] = 0
                reply[:atime_seconds] = 0
                reply[:md5] = 0
                reply[:uid] = 0
                reply[:gid] = 0


                if File.exists?(file)
                    logger.debug("Asked for status of '#{file}' - it is present")
                    reply[:output] = "present"
                    reply[:present] = 1

                    stat = File.stat(file)

                    [:size, :mtime, :ctime, :atime, :uid, :gid].each do |item|
                        reply[item] = stat.send(item)
                    end

                    [:mtime, :ctime, :atime].each do |item|
                        reply["#{item}_seconds".to_sym] = stat.send(item).to_i
                    end

                    reply[:mode] = "%o" % [stat.mode]
                    reply[:md5] = Digest::MD5.hexdigest(File.read(file)) if stat.file?

                    reply[:type] = "directory" if stat.directory?
                    reply[:type] = "file" if stat.file?
                    reply[:type] = "symlink" if stat.symlink?
                    reply[:type] = "socket" if stat.socket?
                    reply[:type] = "chardev" if stat.chardev?
                    reply[:type] = "blockdev" if stat.blockdev?
                else
                    logger.debug("Asked for status of '#{file}' - it is not present")
                end
            end

            def remove
                file = get_filename
                if ! File.exists?(file)
                    logger.debug("Asked to remove file '#{file}', but it does not exist")
                    reply.statusmsg = "OK"
                end

                begin
                    FileUtils.rm(file)
                    logger.debug("Removed file '#{file}'")
                    reply.statusmsg = "OK"
                rescue
                    logger.warn("Could not remove file '#{file}'")
                    reply.fail "Could not remove file '#{file}'", 1
                end
            end

            def touch
                file = get_filename
                begin
                    FileUtils.touch(file)
                    logger.debug("Touched file '#{file}'")
                rescue
                    logger.warn("Could not touch file '#{file}'")
                    reply.fail "Could not touch file '#{file}'", 1
                end
            end
        end
    end
end

