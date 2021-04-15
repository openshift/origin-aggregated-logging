#
# Fluentd
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

require 'fluent/plugin/input'

module Fluent::Plugin
  class WriteWatcher < Fluent::Plugin::Input


      def initialize(log)
        @notify_count = 0
        @log = log
        @map = {}
      end


      # :ino inode number of current file
      # :size of current file
      # :bytes_logged bytes_logged size of previous files for this path
      Entry = Struct.new(:ino, :size,:sum_bytes_collected,:sum_bytes_logged)

      def on_notify(path, stat)
        info = @map[path]
        if !info
          #@log.debug "GETTING TOTALBYTES_LOGGED METRICS FOR #{path} new file"
          info = Entry.new(nil, 0,0,0)
        end
        # Accumulate last size if file changed (no stat, new inode or truncated)
        if !stat || info.ino != stat.ino || stat.size < info.size
          info.size = 0
          info.sum_bytes_logged +=  stat.size if stat 
        elsif  stat.size >= info.size
          info.sum_bytes_logged +=  (stat.size - info.size)
        end
        

        info.ino, info.size = stat.ino, stat.size if stat

        @map[path] = info
      end

      
      def count_total_bytes_collected(bytesread,path)
        info=@map[path]
        info.sum_bytes_collected += bytesread
      end

     def update_total_bytes_logged(path)
       info=@map[path]
       info.sum_bytes_logged
     end
     
     def update_total_bytes_collected(path)
       info=@map[path]
       info.sum_bytes_collected
     end

    end
  end
