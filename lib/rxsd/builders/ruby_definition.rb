# RXSD Ruby Definition builder
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

module RXSD

# Implements the RXSD::ClassBuilder interface to build string Ruby Class Definitions from xsd
class RubyDefinitionBuilder < ClassBuilder

   # implementation of RXSD::ClassBuilder::build
   def build
      return "class #{@klass.to_s}\nend" if Parser.is_builtin? @klass

      # need the class name to build class
      return nil    if @klass_name.nil?

      Logger.debug "building definition for #{@klass}/#{@klass_name}  from xsd"

      # defined class w/ base
      superclass = "Object"
      unless @base_builder.nil?
        if    ! @base_builder.klass_name.nil?
          superclass = @base_builder.klass_name
        elsif ! @base_builder.klass.nil?
          superclass = @base_builder.klass.to_s
        end
      end
      res = "class " + @klass_name + " < " + superclass + "\n"

      validators = ''
      # define accessors for attributes
      @attribute_builders.each { |atb|
        unless atb.nil?
          att_name = nil
          if !atb.attribute_name.nil?
             att_name = atb.attribute_name.underscore
          elsif !atb.klass_name.nil?
             att_name = atb.klass_name.underscore
          else
             att_name = atb.klass.to_s.underscore
          end

          res += "\tattr_accessor :#{att_name}\n"
          validators += "\t\terrors.push('#{@klass_name}::#{att_name}') if #{att_name}.respond_to?('valid?') and !#{att_name}.valid?\n"
        end
      }
      
      initializers = ''
      @validations.each {|v|
        if v[0] == 'min_exclusive'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_f > #{v[1]}\n"
        elsif v[0] == 'min_inclusive'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_f >= #{v[1]}\n"
        elsif v[0] == 'max_exclusive'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_f < #{v[1]}\n"
        elsif v[0] == 'max_inclusive'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_f <= #{v[1]}\n"
        elsif v[0] == 'total_digits'
          puts "TODO: UNSUPPORTED VALIDATION TYPE: #{v[0]}"
        elsif v[0] == 'fraction_digits'
          validators += "\t\tn = self.to_s.split('.')\n"
          validators += "\t\terrors.push('#{v[0]}') unless n.size == 2 and n[1].length == #{v[1]}\n"
        elsif v[0] == 'length'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_s.length == #{v[1]}\n"
        elsif v[0] == 'min_length'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_s.length >= #{v[1]}\n"
        elsif v[0] == 'max_length'
          validators += "\t\terrors.push('#{v[0]}') unless self.to_s.length <= #{v[1]}\n"
        elsif v[0] == 'enumerations'
          arr = v[1].collect {|i| "'#{i}'"}.join(', ')
          validators += "\t\terrors.push('#{v[0]}') unless [#{arr}].include? self.to_s\n"
        elsif v[0] == 'whitespace'
          puts "TODO: UNSUPPORTED VALIDATION TYPE: #{v[0]}"
        elsif v[0] == 'pattern'
          puts "TODO: UNSUPPORTED VALIDATION TYPE: #{v[0]}"
        elsif v[0] == 'choice' # Handles situations where a choice option is in the schema.
          validators += "\t\tused = 0\n"
          v[1].each{|opt| validators += "\t\tused += 1 unless #{opt}.nil?\n"}
          validators += "\t\terrors.push('#{v[0]}') unless used == 1\n"
        else
          puts "WARNING: UNSUPPORTED VALIDATION TYPE: #{v[0]}"
        end
      }
      
      unless validators.blank?
        res += "\n\tdef valid?\n\t\terrors = []\n#{validators}\t\terrors\n\tend\n"
      end
      
      res += "end"

      Logger.debug "definition #{res} built, returning"
      return res
   end

end

end
