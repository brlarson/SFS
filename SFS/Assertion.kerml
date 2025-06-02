library package Assertion {

private import Metaobjects::SemanticMetadata;
private import ScalarValues::String;

metaclass Assert specializes SemanticMetadata {
	doc
	/*
	 * Assert attaches temporal logic formulas to KerML elements
	 */
	feature n[0..1] : String;  //name
	feature f[1..*] : String;  //well-formed formula
}

}