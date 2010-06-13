# The XSD Restriction definition
#
# Copyright (C) 2010 Mohammed Morsi <movitto@yahoo.com>
# See COPYING for the License of this software

module RXSD
module XSD

# XSD Restriction defintion
# http://www.w3schools.com/Schema/el_restriction.asp
class Restriction

  # restriction attributes
  attr_accessor :id, :base

  # restriction group children
  attr_accessor :group, :choice, :sequence, :attributes, :attribute_groups, :simple_type

  # restrictions
  attr_accessor :min_exclusive, :min_inclusive, :max_exclusive, :max_inclusive, 
                :total_digits, :fraction_digits, :length, :min_length, :max_length,
                :enumerations, :whitespace, :pattern

  # restriction parent
  attr_accessor :parent

  # xml tag name
  def self.tag_name
    "restriction"
  end

  # return xsd node info
  def info
    "restriction id: #{@id} base: #{@base.nil? ? "" : (@base.class == String || Parser.is_builtin?(@base)) ? @base : @base.name }"
  end

  # returns array of all children
  def children
    c = []
    c.push @group  unless @group.nil?
    c.push @choice unless @choice.nil?
    c.push @sequence unless @sequence.nil?
    c += @attributes unless @attributes.nil?
    c += @attribute_groups unless @attribute_groups.nil?
    c.push @simple_type unless @simple_type.nil?
    return c
  end

  # node passed in should be a xml node representing the restriction
  def self.from_xml(node)
     restriction = Restriction.new
     restriction.parent = node.parent.related
     node.related = restriction

     # TODO restriction attributes: | anyAttributes
     restriction.id       = node.attrs["id"]
     restriction.base     = node.attrs["base"]

     if node.parent.name == ComplexContent.tag_name
       # TODO restriction children: | anyAttribute
       restriction.group       = node.child_obj Group
       restriction.choice      = node.child_obj Choice
       restriction.sequence    = node.child_obj Sequence
       restriction.attributes  = node.children_objs Attribute
       restriction.attribute_groups  = node.children_objs AttributeGroup

     elsif node.parent.name == SimpleContent.tag_name
       # TODO restriction children: | anyAttribute
       restriction.attributes       = node.children_objs Attribute
       restriction.attribute_groups = node.children_objs AttributeGroup
       restriction.simple_type   = node.child_obj SimpleType
       parse_restrictions(restriction, node)

     else # SimpleType
       restriction.attributes              = []
       restriction.attribute_groups        = []
       restriction.simple_type = node.child_obj SimpleType
       parse_restrictions(restriction, node)

     end

     return restriction
  end

  # resolve hanging references given complete xsd node object array
  def resolve(node_objs)
    unless @base.nil?
      builtin  = Parser.parse_builtin_type @base
      simple   = node_objs[SimpleType].find  { |no| no.name == @base }
      complex  = node_objs[ComplexType].find { |no| no.name == @base }
      if !builtin.nil?
        @base = builtin
      elsif !simple.nil?
        @base = simple
      elsif !complex.nil?
        @base = complex
      end
    end
  end

  # convert restriction to class builder
  def to_class_builder(cb = nil)
     unless defined? @class_builder
       @class_builder = cb.nil? ? ClassBuilder.new : cb

       # convert restriction to builder 
       if Parser.is_builtin? @base
         @class_builder.base = @base
       elsif !@base.nil?
         @class_builder.base_builder = @base.to_class_builder
       end

       unless @group.nil?
         @group.to_class_builders.each { |gcb|
           @class_builder.attribute_builders.push gcb
         }
       end

       unless @choice.nil?
         @choice.to_class_builders.each { |ccb|
           @class_builder.attribute_builders.push ccb
         }
       end

       unless @sequence.nil?
         @sequence.to_class_builders.each { |scb|
           @class_builder.attribute_builders.push scb
         }
       end

       @attributes.each { |att|
          @class_builder.attribute_builders.push att.to_class_builder
       }

       @attribute_groups.each { |atg|
          atg.to_class_builders.each { |atcb|
             @class_builder.attribute_builders.push atcb
          }
       }

       unless @simple_type.nil?
         @class_builder.attribute_builders.push @simple_type.to_class_builder
       end

       # FIXME add facets
       unless @min_exclusive.nil?
         @class_builder.validations.push ['min_exclusive', @min_exclusive]
       end
       
       unless @min_inclusive.nil?
         @class_builder.validations.push ['min_inclusive', @min_inclusive]
       end
       
       unless @max_exclusive.nil?
         @class_builder.validations.push ['max_exclusive', @max_exclusive]
       end
       
       unless @max_inclusive.nil?
         @class_builder.validations.push ['max_inclusive', @max_inclusive]
       end
       
       unless @total_digits.nil?
         @class_builder.validations.push ['total_digits', @total_digits]
       end
       
       unless @fraction_digits.nil?
         @class_builder.validations.push ['fraction_digits', @fraction_digits]
       end
       
       unless @length.nil?
         @class_builder.validations.push ['length', @length]
       end
       
       unless @min_length.nil?
         @class_builder.validations.push ['min_length', @min_length]
       end
       
       unless @max_length.nil?
         @class_builder.validations.push ['max_length', @max_length]
       end
       
       unless @enumerations.nil?
         @class_builder.validations.push ['enumerations', @enumerations]
       end
       
       unless @whitespace.nil?
         @class_builder.validations.push ['whitespace', @whitespace]
       end
       
       unless @pattern.nil?
         @class_builder.validations.push ['pattern', @pattern]
       end
     end

     return @class_builder
  end

  # return all child attributes assocaited w/ restriction
  def child_attributes
     atts = []
     atts += @base.child_attributes unless @base.nil? || ![SimpleType, ComplexType].include?(@base.class)
     atts += @sequence.child_attributes  unless @sequence.nil?
     atts += @choice.child_attributes unless @choice.nil?
     atts += @group.child_attributes  unless @group.nil?
     atts += @simple_type.child_attributes unless @simple_type.nil?
     @attribute_groups.each { |atg| atts += atg.child_attributes } unless @attribute_groups.nil?
     @attributes.each       { |att| atts += att.child_attributes } unless @attributes.nil?
     return atts
  end


  private

    # internal helper method
    def self.parse_restrictions(restriction, node)
       restriction.min_exclusive = node.child_value("minExclusive").to_i unless node.child_value("minExclusive").blank?
       restriction.min_inclusive = node.child_value("minInclusive").to_i unless node.child_value("minInclusive").blank?
       restriction.max_exclusive = node.child_value("maxExclusive").to_i unless node.child_value("maxExclusive").blank?
       restriction.max_inclusive = node.child_value("maxInclusive").to_i unless node.child_value("maxInclusive").blank?
       restriction.total_digits  = node.child_value("totalDigits").to_i unless node.child_value("totalDigits").blank?
       restriction.fraction_digits  = node.child_value("fractionDigits").to_i unless node.child_value("fractionDigits").blank?
       restriction.length        = node.child_value("length").to_i unless node.child_value("length").blank?
       restriction.min_length    = node.child_value("minLength").to_i unless node.child_value("minLength").blank?
       restriction.max_length    = node.child_value("maxLength").to_i unless node.child_value("maxLength").blank?
       restriction.enumerations  = node.child_values "enumeration"
       restriction.enumerations  = nil if restriction.enumerations.empty?
       restriction.whitespace    = node.child_value "whitespace" unless node.child_value('whitespace').blank?
       restriction.pattern       = node.child_value "pattern" unless node.child_value('pattern').blank?
    end

end

end # module XSD
end # module RXSD
