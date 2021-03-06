# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

require File.join(File.dirname(__FILE__), '..', 'progressbar')

module TaliaUtil
  
  # Helper class for command-line progress bars as progressor objects
  class BarProgressor
    
    def self.run_with_progress(message, size)
      progress = ProgressBar.new(message, size)
      yield(progress)
      progress.finish
    end
    
  end
end