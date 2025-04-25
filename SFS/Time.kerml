library package Time {
  private import ScalarValues::Real;
  private import ScalarValues::Boolean;
  private import Base::DataValue;
  private import Assertion::Assert;
  
  type Instant specializes Real {
    doc /* an instant of time */
  }
  
  type Interval specializes DataValue {
    doc /* an interval between instants
     * is empty if lowerBound = upperBound
     * and openLeft or openRight
     */
    @Assert{f="lowerBound <= upperBound";}
    feature lowerBound : Instant;
    feature upperBound : Instant;
    feature openLeft : Boolean;
    feature openRight : Boolean;    
  }

}