//AADL_Example_Ports.sysml

//sending integers between AADL threads through AADL ports using AADL interfaces

package UnitCaseModel_AADLPortCommunication {
  doc /* 
   * Sending integers between AADL threads through AADL ports using AADL interfaces
   * w/o using AADL.sysml library itself
   */
  
  private import IPI::*;  // in ItemPortInterface.sysml
  private import ScalarValues::Integer;
  private import States::StateAction;
//  private import AADL::*;

  part def Thread {
    doc /*
     * This is a placeholder for AADL::Thread to be independent of AADL.sysml
     */
  }
  
  item def AadlData {
    doc 
    /* specialize AadlData and specialize 'value'
     * to be data type sent/received by the AADL data port
     */
    attribute value : Base::DataValue;
  }

  item def IntegerItem :> AadlData {
    doc /* create an AADL item to hold the integer value */
    attribute value : ScalarValues::Integer redefines value;
  }

  port def IntegerPort :> DataPort {
    doc /* create an AADL data port to move the item which holds the integer */
    out item itm : IntegerItem redefines itm;
  }

  interface def IntegerConnection :> DataConnection {
    /* create an interface (used like connection) to transfer items between ports */
    end source : IntegerPort redefines source;
    end target : ~IntegerPort redefines target;
  }

  part def PingPong :> Thread {
    /* this is an AADL thread which does something */
    port snd : IntegerPort;  //out
    port rcv : ~IntegerPort; //in
    
    attribute count : Integer := 0;  //integer value we send
    
    state Machine {
      doc /* state machines must be contained in a state */
      
      state init : StateAction;  //initial state
      state run : StateAction;   //complete state
 
      entry; then init; /* entrypoint for Machine transitions to initial state init */
      
      //send the first item
      transition T1
        first init
        then run {
        send IntegerItem(count) via snd;
        }
      
      //get an item, send an item back 
      transition T2
        first run
        accept i : IntegerItem via rcv
        then run {
          assign count := i.value + 1;
          send IntegerItem(count) via snd;
        }
        
    }   
  }



}
