module CardData
  def extract_plus_data!
    keys.inject({}) {|h,k| h[k] = delete(k) if k =~ /^\+/; h }
  end
end

module Card
  class << self
    def create_or_update args
      if c = Card[ args[:name] ]
        c.update_attributes args
        c
      else
        c= Card.new args
        c.save!
        #Card.create! args
        c
      end
    end

    def save_all_log_entry( name, content, prefix="\t" )
      "Card SaveAll: #{prefix}#{name}, " + (content||"").gsub("\n","")[0..50] + "\n"
    end
    
    def save_all data, opts = {}
      options = {
        :strategy => :create_or_update,  # :find_or_new, :create!, :update
        :plus_strategy => :create_or_update
      }.merge( opts )

      data.extend CardData
      plusses = data.extract_plus_data!

      log = ""
      time = Benchmark.measure do 
        Card::Base.transaction do
          base_card = Card.send options[:strategy], data

          plusses.each do |plus_name, plus_data|
            plus_card_name = base_card.name + plus_name
            case plus_data
              when String;  
                Card.send options[:plus_strategy], :name=> plus_card_name, :content => plus_data
                log << save_all_log_entry( plus_card_name, plus_data)

              when Array;
                if block_given?
                  plus_data = plus_data..map{|x| yield(plus_name, x) }
                end
                card_args = {
                  :name => plus_card_name, 
                  :type => "Pointer",  
                  :content => plus_data.map{|x| "[[#{x}]]" }.join("\n")
                }
                Card.send options[:plus_strategy], card_args
                log << save_all_log_entry( card_args[:name], card_args[:content])
              when Hash;
                plus_data[:name] ||= plus_card_name
                Card.send options[:plus_strategy], plus_data
                log << save_all_log_entry( plus_data[:name], plus_data[:content])
            end
          end
        end
      end
      log = save_all_log_entry( data[:name], data[:content], prefix="(+#{plusses.size}, #{sprintf("%.3f",time.real)}s)  ") + log
      ActiveRecord::Base.logger.info log
    end
  end
end  

