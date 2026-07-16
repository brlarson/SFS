//send_accept.sysml

package 'send accept' {
  doc /*
  * direct send-accept
  */

  private import ScalarValues::Integer;
	private import VerificationCases::*;

  item def MyItem {
    value : Integer;
  }

  part def PartC {
    part PartA {
      action ActionA {
        send new MyItem(4) to PartB;
      }
    }

    part PartB {
      item mi : MyItem;
      action ActionB {
        accept mi : MyItem;
      }
    }
  }
  
  verification 'send accept' {
    subject subj : PartC;

    doc /*
    * Expectation:
    * Actions will execute w/o 'perform'
    * ActionA will put a MyItem with value 4 into PartA.outgoingBuffer and
    * create a Message from PartA to PartB.
    * The Message moves MyItem from PartA.outgoingBuffer to PartB.incomingBuffer.
    * ActionB removes MyItem from PartB.incomingBuffer and puts it in mi.
    */
  }
}
