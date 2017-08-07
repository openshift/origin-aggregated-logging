module LoopHelpers
    
    # loop until timeout or 
    # the provided block returns true
    def loop_maximum(max, duration=1.0)
       tot = 0
       loop do
           unless yield #continue to loop while block is false
             return true unless tot < max
             tot = tot + duration
             sleep(duration)
           else
               return false
           end
       end
    end
end
