//bad_accept_filter.sysml

package 'bad accept filter' {
  doc /*
  * type of accept is not type of payload sent, so the accept never occurs:
  * AcceptPerformance waits for an item in the incomingBuffer that conforms
  * to the accepted type (SysML v2 8.4.13.6), and since only a MyItem is
  * ever sent, no YourItem is ever available to accept.
  */

  private import ScalarValues::Integer;
	private import VerificationCases::*;

  item def MyItem {
    value : Integer;
  }

  item def YourItem {
    value : Integer;
  }

  port def MyPort {
    out mi : MyItem;
  }

  port def YourPort {
    in yi : YourItem;
  }

  interface def MyInterface {
    end source : MyPort;
    end target : YourPort;
    flow myFlow of MyItem from source.mi to target.yi;
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
      port portB : YourPort;
      item yourItem : YourItem;
      action ActionB {
        accept yourItem : YourItem via portB.yi;
      }
    }
  }
  
  verification 'bad accept filter' {
    subject subj : PartC;

    doc /*
    * Expectation:
    * ActionB's accept never completes, even though PartB.portB.yi.incomingBuffer
    * is non-empty, because the only item ever sent is a MyItem and it does not
    * conform to yourItem's type, YourItem. ActionB waits indefinitely instead of
    * accepting the non-conforming item and yielding the empty sequence, ().
    */
  }
}
