module ActsAsConstantClassMethods

  def ActsAsConstantClassMethods.extend_object(o)
   # puts "ActsAsConstantClassMethods added to #{o.inspect}"
    super
  end

  def acts_as_constant(col = :name)
    begin
      #puts self.to_s
      # let's set up a variable to represent the name of the klass
      klass = self.to_s
      #puts "klass = #{klass}"
      const = klass.upcase.gsub("::", "_")
      #puts "const = #{const}"
      
      define_method("constantize") do
        self.send(col).constantize
      end
      
      class_eval %{
        def self.acts_as_constant_class_name
          "#{const}"
        end
        
        def self.acts_as_constant_column
          "#{col}"
        end
      }
      
      # create a constant array to hold the values
      # create a nice get method to pull from the constant array
      class_eval %{
        private
        ACTS_AS_CONSTANT_CONSTANTS = [] unless const_defined?("ACTS_AS_CONSTANT_CONSTANTS")
        
        public
        def self.acts_as_constant_get(id)
          return nil if id.blank?
          ACTS_AS_CONSTANT_CONSTANTS[id]
        end
        
        def self.ACTS_AS_CONSTANT_CONSTANTS
          ACTS_AS_CONSTANT_CONSTANTS
        end

      }
      
      class_eval do
        def self.reload_constants!
          begin
            self.ACTS_AS_CONSTANT_CONSTANTS.clear
            # eval %{self.ACTS_AS_CONSTANT_CONSTANTS.clear}
            
            rows = self.to_s.constantize.all

            rows.each do |rec|
              #puts rec.inspect
              name = rec.send(self.acts_as_constant_column)

              unless name.nil?

                # let's sanitize the name a bit.
                name = name.methodize

                self.instance_eval do

                  define_method("acts_as_constant_name") do
                    self.send(self.acts_as_constant_column).methodize
                  end

                end                                                                        
                # puts "creating...#{self.constant_class_name}.#{name}"
                # let's create two methods an all downcase method for accessing the constant and an upper case one
                class_eval %{
                  # by using .freeze we can prevent the object from being modified.
                  ACTS_AS_CONSTANT_CONSTANTS[#{rec.id}] = rec.freeze

                  def self.#{name}
                    ACTS_AS_CONSTANT_CONSTANTS[#{rec.id}]
                  end

                  def self.#{name.upcase}
                    ACTS_AS_CONSTANT_CONSTANTS[#{rec.id}]
                  end
                }
              end
            end
          rescue Exception => e
            pp e
          end
          
        end
      end
      
      self.reload_constants!
      
    rescue => ex
      puts "Error in acts_as_constant: #{ex.message}"
      puts ex.backtrace  
    end
    
  end

end 

module ActsAsConstant
  def self.included(model)
    #puts "including  DataMapper::ActsAsConstantClassMethods in #{model.inspect}"
    model.extend  ActsAsConstantClassMethods
  end
end

DataMapper::Resource.append_inclusions(ActsAsConstant)
