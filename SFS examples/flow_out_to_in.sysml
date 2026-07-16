//flow_out_to_in.sysml

package 'flow out to in' {
  doc /* Transmit a value between actions by binding one action's output to another
  *  action's input.
  */

  private import ScalarValues::Integer;
	private import VerificationCases::*;

  action MyAction {
    action A {
      out a:Integer;
      action putIt assign a := 5;
      first start then putIt;
      first putIt then done;
    }

    action B {
      in b:Integer;
      attribute v:Integer := 3;
      action getIt assign v := b;
      first start then getIt;
      first getIt then done;
    }

    flow myFlow of Integer from A.a to B.b;
    
    first start then A;
    first A then B;
    first B then done;
  }  

  verification 'flow out to in' {

    perform action MyAction;

//    return verdict : VerdictKind = PassIf(MyAction.B.v == 5);
// error reaching into action B

  doc /*
  * Expectation A puts out A.a=5; B.b gets 5 from the flow from A.a;
  * B.v is assigned 5.
  *
  * 'flow' is a Flows::Message which is both Actions::Action and 
  * Transfers::Transfer.  Transfer.source and Transfer.target are
  * both Occurrence, which work fine for A and B.  
  * sourceOutput is redefined as A.a and targetInput becomes B.b.
  *
  * myFlow is an Occurrence which must exist during A and B
  * 
  */

  }
}

