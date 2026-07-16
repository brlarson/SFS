//send_via_accept.sysml

package 'send via accept' {
  doc /*
  * indirect send-accept, via some other sender
  */

  private import ScalarValues::Integer;
	private import VerificationCases::*;

  item def MyItem {
    value : Integer;
  }

  part def PartC {
    part PartA {
      action ActionA {
        send new MyItem(4) via PartD to PartB;
      }
    }

    part PartD;

    part PartB {
      item mi : MyItem;
      action ActionB {
        accept mi : MyItem via PartB;
      }
    }
  }
  
  verification 'send via accept' {
    subject subj : PartC;

    doc /*
    * Expectation:
    * Actions will execute w/o 'perform'
    * ActionA will put a MyItem with value 4 into PartD.outgoingBuffer and
    * create a Message from PartD to PartB.
    * The Message moves MyItem from PartD.outgoingBuffer to PartB.incomingBuffer.
    * ActionB removes MyItem from PartB.incomingBuffer and puts it in mi.
    */
  }
}
