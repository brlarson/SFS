//bind_out_to_in.sysml

package 'Bind out to in' {
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

    bind A.a = B.b;
    
    first start then A;
    first A then B;
    first B then done;
  }  

  verification 'Bind out to in' {

    perform action MyAction;

//    return verdict : VerdictKind = PassIf(MyAction.B.v == 5);
// error reaching into action B

  doc /*
  * Expectation A puts out A.a=5; B.b gets 5 because it's bound to A.a;
  * B.v is assigned 5.
  *
  * If B is immediate successor to A then the binding of A.a=B.b is like
  * passing a parameter to a subprogram.
  *
  * But if A ends before B begins (it's a non-immediate succession),
  * where does the value 5 exist?
  */

  }
}