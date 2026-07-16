//port_interface_flow.sysml

package 'port interface flow' {
  doc /*
  * send via port, move between ports by flow on interface, receive via port
  */

  private import ScalarValues::Integer;
	private import VerificationCases::*;

  item def MyItem {
    value : Integer;
  }

  port def MyPort {
    out mi : MyItem;
  }

  interface def MyInterface {
    end source : MyPort;
    end target : ~MyPort;
    flow myFlow of MyItem from source.mi to target.mi;
  }

  part def PartC {
    part PartA {
      port portA : MyPort;
      action ActionA {
        send new MyItem(6) via portA.mi;
      }
    }

    interface myInt : MyInterface connect PartA.portA to PartB.portB; 

    part PartB {
      port portB : ~MyPort;
      item myItem : MyItem;
      action ActionB {
        accept myItem : MyItem via portB.mi;
      }
    }
  }
  
  verification 'port interface flow' {
    subject subj : PartC;

    doc /*
    * Expectation:
    * Actions will execute w/o 'perform'
    * ActionA will put a MyItem with value 6 into PartA.portA.mi.outgoingBuffer 
    * flow myFlow creates a Message from PartA.portA.mi to PartB.portB.mi.
    * The Message moves MyItem from PartA.portA.mi.outgoingBuffer to PartB.portB.mi.incomingBuffer.
    * ActionB removes MyItem from PartB.portB.mi.incomingBuffer and puts it in myItem.
    */
  }
}
