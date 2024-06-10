# Godot XML
An API to load XML files using GDScript in Godot 3.5.2.

This repository contains the GDScript file for an XML Document API that I created for use with one of my projects.
Currently, this API only allows loading the entire XML Document at once, and is not intended to support all XML features.

## Getting Started
Add the `XML.gd` file to your Godot project. Godot should now allow you to access the XML class within your own scripts.

### Example
Consider the following (semi-awkward) XML-like Document as the data you wish to load:
```xml
<items>
   <item id="55000">
      <name>Gauntlet Potion</name>
      <use_state>Combat</use_state>
      <requires_skill>1016</requires_skill>
      <effects>
         <damage_effect element="Dark">
            <base>100</base>
            <aoe radius="7" max_targets="5" />
         </damage_effect>
         <skill_effect>1021</skill_effect>
      </effects>
   </item>
</items>
```

____________________
#### Simple Approach
The simplest way to open an XML Document is to call `XML::open` with the path to the file. If the above XML Document were located at
`res://Data/sample.xml`, then you could open the entire thing like so:
```GDScript
var xml_root: XML.Element = XML.open("res://Data/sample.xml");
```

From there, you would have access to the XML Attributes, XML Element children, and the text data through the `XML.Element` properties:
`valid_attributes`, `valid_children`, and `text_content`.

Note: Despite 'valid' being included in the property names for attributes and children, actual XML Document validation is not performed
by the implementation of this API. Instead, 'valid' in this context is referring to the notion that the attributes and children found
within these properties were expected by the `XML.Element` implementation that stores them.

______________________
#### Advanced Approach
The simple approach above is sufficient for basic needs while loading String data; but, with a slightly more advanced approach, this API
also allows for converting to specific data types while parsing the XML Document. Through subclassing `XML.Element`, and
`XML.AttributeConverter`, as necessary, it's possible to specify the entire expected structure of the XML Document (or filter it down to
data of interest to you), including the data types and conversion logic for each XML Element, XML Attribute, and XML Element text data.
This ultimately becomes increasingly verbose; but, the subclasses could be generated via automation tools if the definition of the
XML Document's structure is already available.

After the XML Document has been loaded, it's still then up to the user to traverse the result, as in the simple approach. For the sake of
brevity in the README, an example implementation of a more advanced approach will not be provided. Instead, advanced users are encouraged
to read the documentation comments included in the implementation itself (inside the `XML.gd` file).

____________________________________________________________________________
You may use this under the terms of the license included in this repository.

Please also see the license information for Godot, found here: https://godotengine.org/license/
