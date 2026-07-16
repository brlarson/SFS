//send_accept.sysml

package 'send fork accept' {
  doc /*
  * parallel actions can accept; only one will; done will not be reached
  * This is different than PSSM which says both will accept the same thing. 
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
      action ActionB {
        action ActionB1 {
          item mi1 : MyItem;
          accept mi1 : MyItem via PartB;
        }
        action ActionB2 {
          item mi2 : MyItem;
          accept mi2 : MyItem via PartB;
        }
        fork forkB;
        join joinB;

        first start then forkB;
        first forkB then ActionB1;
        first forkB then ActionB2;
        first ActionB1 then joinB;
        first ActionB2 then joinB;
        first joinB then done;
      }
    }
  }
  
  case 'send fork accept' {
    subject subj : PartC;

    doc /*
    * Expectation:
    * ActionA and ActionB will execute w/o 'perform'
    * ActionA will put a MyItem with value 4 into PartA.outgoingBuffer and
    * create a Message from PartA to PartB.
    * The Message moves MyItem from PartA.outgoingBuffer to PartB.incomingBuffer.
    *
    * One of ActionB1 or ActionB2 NONDETERMINISTICALLY removes MyItem from
    * PartB.incomingBuffer and puts it in either mi1 or mi2.
    */
  }
}
