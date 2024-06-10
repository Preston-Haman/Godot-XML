# An API to parse XML Document Elements using the built-in XMLParser. Conversion from String values
# to explicit data types while reading the XML Document is supported via subclassing XML.Element
# and XML.AttributeConverter.
# 
# This implementation is not intended to handle every XML feature. It is made to handle simple
# XML Documents that mainly include typical XML Elements with XML Attributes, and typical child
# XML Elements OR text content (use of both may result in odd behaviour).
# 
# As an example, the following XML-like Document would be easy to parse with this implementation
# (though this particular Document's structure may be considered a little odd):
# 	<items>
# 		<item id="55000">
# 			<name>Gauntlet Potion</name>
# 			<use_state>Combat</use_state>
# 			<requires_skill>1016</requires_skill>
# 			<effects>
# 				<damage_effect element="Dark">
# 					<base>100</base>
# 					<aoe radius="7" max_targets="5" />
# 				</damage_effect>
# 				<skill_effect>1021</skill_effect>
# 			</effects>
# 		</item>
# 	</items>
# 
# However, XML-like Documents that start to become more complex, such as the HTML of a webpage,
# or XML Documents utilizing more advanced features (such as CDATA elements), are ill suited for
# parsing by this implementation; and, attempting to parse such documents is likely to go wrong.
# 
# Documents can be fully loaded into memory via a call to XML::open. The resulting XML.Element can
# then be examined, or have its children iterated. It's encouraged to subclass XML.Element for the
# sake of defining the expected structure of the XML Document; but, is ultimately not required.
class_name XML extends Reference


# Data types supported by XML.AttributeConverter.
enum DataType {
	# The data stored in the associated XML Attribute is a String. No conversion will take place.
	STRING,
	
	# The data stored in the associated XML Attribute is an integer (in base 10).
	INT,
	
	# The data stored in the associated XML Attribute is a floating point value (in base 10; and,
	# also supports exponential notation strings as defined by GDScript's float constructor).
	FLOAT,
	
	# The data stored in the associated XML Attribute is a boolean. The default implementation
	# will parse false for any value that doesn't match the text "true" (not case sensitive).
	BOOL,
	
	# The data stored in the associated XML Attribute is a user-defined type.
	# 
	# Specifying this implies that the associated instance of XML.AttributeConverter is a custom
	# subclass; and, that the XML.AttributeConverter::_convert method has been overridden.
	CUSTOM,
}


# Converts an XML Attribute value that can be found inside an XML Element's attributes from a
# String into a data type that better represents it.
# 
# For example, consider the following XML snippet:
# 	<user_tag user_attribute="True">
# 		...
# 	</user_tag>
# 
# An instance of this class would be able to convert the attribute's value string ("True") into a
# more convenient data type -- in this case, a bool. This is achieved through calling
# XML.AttributeConverter::get_converted_value, passing the value string.
# 
# The data type of the converted value associated with the attribute is specified in data_type by
# the XML.DataType enum constants. The XML.AttributeConverter::_convert method must be overridden
# to parse custom data types.
class AttributeConverter extends Reference:
	
	# Defines how the value string for the associated XML Attribute will be interpreted by this
	# XML.AttributeConverter.
	# 
	# This should be one of the XML.DataType enum constants. If XML.DataType.CUSTOM is used,
	# that implies the current instance of XML.AttributeConverter is a custom subclass that also
	# overrides the XML.AttributeConverter::_convert method. If an unknown value is used, then
	# it will be treated as if it were XML.DataType.CUSTOM.
	var data_type: int;
	
	# Creates an XML.AttributeConverter that converts value strings into a data type that reflects
	# the given data_type_ value.
	# 
	# data_type_:
	# 	An XML.DataType constant that defines the associated data type for this
	# 	XML.AttributeConverter.
	func _init(data_type_: int = DataType.STRING) -> void:
		data_type = data_type_;
	
	# Converts the given value string into a more appropriate type to represent the data. The type
	# returned reflects the type specified by the XML.DataType constant stored in data_type.
	# 
	# For non-custom types, the value is converted and returned within this implementation; however,
	# if this XML.AttributeConverter is for a custom type, the value from
	# XML.AttributeConverter::_convert is returned, instead.
	# 
	# value:
	# 	The value string from the XML Attribute to parse and return a more appropriate data type
	# 	for.
	func get_converted_value(value: String):
		match (data_type):
			DataType.STRING:
				return value;
			DataType.INT:
				return int(value);
			DataType.FLOAT:
				return float(value);
			DataType.BOOL:
				# The result is inverted because 0 is false; but, 0 from comparison is equality.
				return !"true".nocasecmp_to(value);
			_:
				# While we could specify DataType.CUSTOM, let's use the default case on the off
				# chance someone really wants to specify what their custom type is with the value
				# in data_type. Not sure why someone might do this; but, it's fine.
				return _convert(value);
		# End match
	
	# Helper method for XML.AttributeConverter::get_converted_value. Subclasses that convert value
	# strings into custom data types should override this method to return a custom data type
	# that represents the given value.
	# 
	# The default implementation merely returns the value string as-is.
	# 
	# value:
	# 	The value string from the XML Attribute to parse and return a custom data type
	# 	representation of.
	func _convert(value: String):
		assert(false, "Subclasses should override this method when converting custom data types.");
		return value;


# Represents an XML Element that exists within an XML Document.
# 
# Subclasses must ensure their Object::_init override requires zero arguments.
# 
# Subclasses are encouraged to filter the data they maintain down to what is relevant for their
# usage by overriding XML.Element::_supports_attribute, and XML.Element::_supports_child_element.
# It's also encouraged to override XML.Element::_set_attribute for the purpose of including
# convenience properties.
# 
# If this XML.Element is a wrapper for text data that is to be parsed and converted into a custom
# type, then XML.Element::_convert_text_data must be overridden to parse the text and return the
# type it represents.
class Element extends Reference:
	
	# The name of the XML Element.
	# 
	# As an example, consider the following XML snippet:
	# 	<aoe radius="7" max_targets="5" />
	# 
	# In this example, the XML Element's tag name would be 'aoe'.
	var tag: String;
	
	# If true, the text data is relevant; and, text_content will be populated.
	# 
	# If necessary, XML.Element::_convert_text_data should be overridden when true.
	var is_wrapper: bool;
	
	# A dictionary of attributes mapped by their names to their values. XML Attributes are only
	# populated if XML.Element::_supports_attribute returns an XML.AttributeConverter instance.
	# 
	# The values have been converted to their proper type via the XML.AttributeConverter supplied by
	# XML.Element::_supports_attribute.
	var valid_attributes: Dictionary = {};
	
	# An array of child elements of this element. XML Elements are only populated here if
	# XML.Element::_supports_child_element returns an XML.Element instance.
	# 
	# Each value in this array is an XML.Element instance representing an XML Element from an XML
	# Document.
	var valid_children: Array = [];
	
	# Populated if is_wrapper is true; this is the text data of the element.
	var text_content: String = "";
	
	# Creates an XML.Element to represent XML Element nodes in an XML Document. The given tag_ is
	# the associated XML Element name. If is_wrapper is true, the text between the Element's opening
	# and closing tags will also be parsed (and stored in text_content with leading/trailing
	# whitespace trimmed).
	# 
	# Subclasses must ensure that any overrides of this method are callable without arguments. This
	# requirement stems from the implementation of the static XML.Element::copy_template method.
	# 
	# tag_:
	# 	The tag name of the XML Element this XML.Element represents.
	# 
	# is_wrapper:
	# 	If true, the text data of this XML.Element will also be parsed.
	func _init(tag_: String = "", is_wrapper_: bool = false) -> void:
		tag = tag_;
		is_wrapper = is_wrapper_;
	
	# If is_wrapper is true, and the text_content is not empty, returns the result of passing
	# text_content to XML.Element::_convert_text_data; otherwise, returns null.
	func get_wrapped_value():
		if (is_wrapper and !text_content.empty()):
			return _convert_text_data(text_content);
		
		return null;
	
	# Returns an appropriate XML.AttributeConverter instance for the given attribute_tag if it's
	# supported by this XML.Element. If the specified tag is not expected, then null is returned.
	# 
	# The default implementation supports all XML Attributes; treating each one as if it represents
	# String data. Subclasses should consider overriding this behaviour to only support
	# XML Attributes that are relevant to their usage.
	# 
	# _attribute_tag:
	# 	The name of the XML Attribute that may be applied on this XML.Element.
	func _supports_attribute(_attribute_tag: String) -> AttributeConverter:
		return AttributeConverter.new();
	
	# Returns an appropriate XML.Element instance for the given element_tag, if it's supported as a
	# child of this XML.Element. If the specified tag is not expected, then null is returned.
	# 
	# The default implementation supports all XML Elements; treating each one as if it's a wrapper
	# that also accepts all children XML Elements and XML Attributes. Subclasses should consider
	# overriding this behaviour to only support child XML Elements that are relevant to their usage.
	# 
	# element_tag:
	# 	The name of the XML Element that may be a child of this XML.Element.
	func _supports_child_element(element_tag: String) -> Element:
		return Element.new(element_tag, true);
	
	# Returns text, parsed and converted to the proper data type.
	# 
	# Subclasses should override this method as necessary; the default implementation merely returns
	# text directly.
	# 
	# text:
	# 	The text to parse and return a custom representation of.
	func _convert_text_data(text: String):
		return text;
	
	# Adds a representation of an XML Attribute to valid_attributes by mapping the given
	# attribute_tag to the specified value. A call is also made to XML.Element::_set_attribute,
	# passing the same arguments as given, for the sake of subclasses that may override it.
	# 
	# attribute_tag:
	# 	The tag of the attribute to apply to this XML.Element.
	# 
	# value:
	# 	The value to associate with the given attribute_tag. The data type is determined by the
	# 	returned XML.AttributeConverter from a call to XML.Element::_supports_attribute.
	func _add_attribute(attribute_tag: String, value) -> void:
		assert(_supports_attribute(attribute_tag), "Invalid attribute!");
		valid_attributes[attribute_tag] = value;
		_set_attribute(attribute_tag, value);
	
	# This method is called internally while the XML Document is being parsed. If a call to
	# XML.Element::_supports_attribute with the given _attribute_tag returns an instance of
	# XML.AttributeConverter, then this method will be supplied with the same _attribute_tag, and
	# the resulting _value of the conversion via a call to XML.Element::_add_attribute.
	# 
	# Subclasses may override this method in order to set convenience fields for attributes. The
	# default implementation does nothing. If a subclass provides all supported attributes as class
	# properties, using the verbatim names of the attributes, a suggested implementation is simply
	# to call Object::set, passing the _attribute_tag and _value.
	# 
	# _attribute_tag:
	# 	The name of the XML Attribute to apply to this XML.Element.
	# 
	# _value:
	# 	The value associated with the given attribute_tag, converted into its proper data type by
	# 	the XML.AttributeConverter supplied by a call to XML.Element::_supports_attribute.
	func _set_attribute(_attribute_tag: String, _value) -> void:
		return;
	
	# Returns a String that roughly approximates how the XML Element this XML.Element represents
	# appeared in the parsed XML Document. The order of the XML Attributes is arbitrary, and the
	# text_content, if any, is shifted to the end of the XML Element.
	# 
	# This implementation is not suitable for generating XML file output. It's intended for
	# debugging purposes.
	func _to_string(tab_count: int = 0) -> String:
		var base_tabs: String = "";
		for __ in range(0, tab_count):
			base_tabs += "\t";
		# End for;
		
		var child_tabs: String = base_tabs + "\t";
		var ret: String = "<%s" % tag;
		
		if (!valid_attributes.empty()):
			for attribute_tag in valid_attributes.keys():
				ret += " %s=\"%s\"" % [attribute_tag, valid_attributes[attribute_tag]];
			# End for
		
		if (valid_children.empty() and (!is_wrapper or text_content.empty())):
			# "empty" tag.
			# I don't think the space here is required; but, it looks better.
			ret += " />";
		else:
			ret += ">";
			if (!valid_children.empty()):
				for child in valid_children:
					ret += "\r\n%s" % child_tabs;
					ret += child._to_string(tab_count + 1);
				# End for
			
			if (is_wrapper and !text_content.empty()):
				var lines = text_content.split("\n");
				if (lines.size() > 1):
					ret += "\r\n%s" % child_tabs;
					ret += lines[0].strip_edges();
					for i in range(1, lines.size()):
						ret += "\r\n%s" % child_tabs;
						ret += lines[i].strip_edges();
					# End for
					
					ret += "\r\n%s" % base_tabs;
				else:
					ret += lines[0];
			else:
				ret += "\r\n%s" % base_tabs;
			
			ret += "</%s>" % tag;
		
		return ret;
	
	# Creates and returns a new XML.Element based on the given template. The values for tag and
	# is_wrapper are copied into the returned XML.Element, which should also maintain the same
	# script (and thereby custom implementation, if applicable) as the template.
	# 
	# template:
	# 	The XML.Element to create an independent copy of.
	static func copy_template(template: Element) -> Element:
		var copy = Reference.new();
		copy.set_script(template.get_script());
		
		# The tag and is_wrapper are the only values that need to be ensured.
		# Suppose checking for equality isn't necessary; but, we can do it anyway...
		var element: Element = copy as Element;
		if (element.tag != template.tag):
			element.tag = template.tag;
		
		if (element.is_wrapper != template.is_wrapper):
			element.is_wrapper = template.is_wrapper;
		
		return element;


# Meant for internal use. Handles the parsing of XML Documents via the built-in XMLParser.
class DefaultParser extends XMLParser:
	
	# The resource path which the XML Document to parse will be found at.
	var xml_file_path: String;
	
	# An XML.Element implementation that defines the root XML Element of the XML Document.
	# 
	# This parser will skip XML Attributes and XML Elements that are not supported by this
	# instance's implementation. Ultimately, the template will not be altered by this parser; but,
	# a copy of its implementation will be returned by a call to XML.DefaultParser::parse.
	# 
	# While it's possible to specify a root_template that does not represent the top-level root
	# node of the XML Document, only the last occurrence of that XML Element will be returned
	# via a call to XML.DefaultParser::parse.
	var root_template: Element;
	
	# Creates a parser for the given xml_file_path_ that will parse an XML Document based on the
	# given root_template_ during a call to XML.DefaultParser::parse.
	# 
	# xml_file_path_:
	# 	The resource path which points to an XML Document to parse.
	# 
	# root_template_:
	# 	An XML.Element implementation that defines the relevant structure of the XML Document.
	func _init(xml_file_path_: String, root_template_: Element) -> void:
		xml_file_path = xml_file_path_;
		root_template = root_template_;
	
	# Parses the XML Document found at xml_file_path based on the root_template and returns
	# the result. If the XML Document could not be parsed, or if none of its data matched the
	# root_template, then null is returned.
	func parse() -> Element:
		if open(xml_file_path) == OK:
			var xml_root: Element;
			
			while read() != ERR_FILE_EOF:
				if get_node_type() == NODE_ELEMENT:
					var node_name: String = get_node_name();
					if (root_template.tag.empty()):
						# If it's empty, then we accept everything.
						root_template.tag = node_name;
					
					if (get_node_name() == root_template.tag):
						# If we're in here, then we found the opening tag of the top-level element
						# of interest to us.
						xml_root = _parse_current_node(root_template);
			# End while
			
			return xml_root;
		
		return null;
	
	# Recursively parses the currently open XML Document, using the given template as a means to
	# define which content of the XML Document is relevant. An independent copy of the template,
	# using the same implementation as defined by XML.Element::copy_template, will be populated
	# and returned.
	# 
	# template:
	# 	An instance of an XML.Element implementation that will act as a template for the returned
	# 	XML.Element.
	func _parse_current_node(template: Element) -> Element:
		# First, make a new instance of template's type so we can return it as a child.
		var current_node: Element = Element.copy_template(template);
		
		# Check for attributes.
		if (get_attribute_count()):
			for i in get_attribute_count():
				var attribute_tag = get_attribute_name(i);
				var converter: AttributeConverter = current_node._supports_attribute(attribute_tag);
				
				if (converter):
					current_node._add_attribute( \
						attribute_tag, converter.get_converted_value(get_attribute_value(i)) \
					);
			# End for
		
		# Check if the node is "empty" (self closing); if it is, then return.
		if is_empty():
			return current_node;
		
		# Otherwise, call read, and check for children, text that is not whitespace (if current_node
		# is a wapper), or the end tag.
		# 
		# While the next node is not the end of our current one...
		while read() != ERR_FILE_EOF \
		and !(get_node_type() == NODE_ELEMENT_END and get_node_name() == current_node.tag):
			match get_node_type():
				NODE_ELEMENT:
					# Child node
					var child_tag: String = get_node_name();
					var child_template: Element = current_node._supports_child_element(child_tag);
					
					if (child_template):
						# Valid child node, parse it (recursive call).
						current_node.valid_children.append(_parse_current_node(child_template));
					else:
						# Invalid child node, skip it.
						skip_section();
				NODE_TEXT:
					# Text data, or whitespace
					var node_text_data: String = get_node_data();
					if (current_node.is_wrapper):
						# The extra leading space is okay because it's trimmed later.
						current_node.text_content += " %s" % node_text_data;
			# End match
		# End while
		
		# Before we go, let's clean the text_content.
		if (current_node.is_wrapper):
			current_node.text_content = current_node.text_content.strip_edges();
		
		return current_node;


# Opens a file located at xml_file_path, and attempts to read an XML Document from it. If a value
# for root_template is provided, then it will be used to determine which parts of the XML Document
# are relevant, as if it were the root node of the XML Document. If it is not the root node of the
# XML Document, it can still be used; however, only the last XML Element that matches it will be
# included in the results.
#
# If a document could be successfully opened and read, the last XML Element matching the
# root_template will be returned, populated with all of its children. If a value for root_template
# was not provided, the default value will result in the unfiltered root node of the XML Document
# being returned.
# 
# Callers are encouraged to provide a custom subclass of XML.Element as the root_template; as, this
# allows for specifying the expected structure of the entire XML Document (within the XML features
# this implementation supports), converting parsed values into custom data types, and offers the
# ability to create convenience methods and properties on the resulting XML.Element and its
# children.
# 
# If the XML Document could not be successfully parsed, null is returned.
# 
# xml_file_path:
# 	The resource path which points to an XML Document to open.
# 
# root_template:
# 	An XML.Element implementation that defines the relevant structure of the XML Document. If not
# 	provided, then the default value will result in the whole document being loaded.
static func open(xml_file_path: String, root_template: Element = Element.new("", true)) -> Element:
	var parser: DefaultParser = DefaultParser.new(xml_file_path, root_template);
	return parser.parse();


# MIT License
# 
# Copyright (c) 2024 Preston Haman
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
