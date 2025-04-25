// PortCommunicationUnitCase.sysml

package PortCommunicationUnitCase {
  
  doc
  /*
   * This case demonstrates that a model that:
   *  exchanges messages between parts through ports over interfaces moved by flow connections.
   * results in:
   *  sequence of "ping-pong" messages between parts
   * Model Description: a pair of parts connected by a pair of interfaces
   * Expectation: sequence of "ping-pong" messages between parts
   */
  
  package UnitCaseModel {
    doc
    /* 
     * The model for the unit cases is here.
     */
    private import Interfaces::BinaryInterface;
    private import FlowConnections::FlowConnection;
    private import ScalarValues::Integer;
    private import States::StateAction;
    
  abstract item def AadlEventData {
    doc 
    /* specialize AadlEventData and specialize 'value'
     * to be data type sent/received by the AADL event data port
     */
    attribute value : Base::DataValue;
  }

  item def IntegerItem :> AadlEventData {
    doc /* create an AADL item to hold the integer value */
    attribute value : ScalarValues::Integer redefines value;
  }

  abstract port def EventDataPort {
    doc
    /*
     * Specialize EventDataPort for the specialized item
     * AadlEventData which specifies the data type of the
     * payload of the items sent.
     * Conjugate the DataPort specialization for 'in' ports
     */
    out item itm : AadlEventData;
  }

  port def IntegerPort :> EventDataPort {
    doc /* create an AADL data port to move the item which holds the integer */
    out item itm : IntegerItem redefines itm;
  }

  interface def EventDataConnection :> BinaryInterface {
    doc
    /*
     * use DataConnection to connect an 'out' event-data port to an 'in' event-data port
     * 'move' performs message transfer from source to target, immediately
     */
    end source : EventDataPort :> source;
    end target : ~EventDataPort :> target; 
    
//    flow move : FlowConnection {
//        end occurrence source : EventDataPort :>> source = BinaryInterface::source;
//        end occurrence target : ~EventDataPort :>> target = BinaryInterface::target;
      }
  }

  interface def IntegerConnection :> EventDataConnection {
    /* create an interface (used like connection) to transfer items between ports */
    end source : IntegerPort redefines source;
    end target : ~IntegerPort redefines target;
  }
    
  part def Ping {
    doc /* 
     * Ping sends the first item.
     * When Ping  receives an item back, it sends again and then halts
     */
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
        then done {
          assign count := i.value + 1;
          send IntegerItem(count) via snd;
        }
        
    }  // end of  state Machine 
  }  //end of Ping
    
  part def Pong {
    doc /* 
     * Pong receives the first item, sends an item back, then halts.
     */
    port snd : IntegerPort;  //out
    port rcv : ~IntegerPort; //in
    
    attribute count : Integer := 0;  //integer value we send
    
    state Machine {
      doc /* state machines must be contained in a state */
      
      state init : StateAction;  //initial state
      state run : StateAction;   //complete state
 
      entry; then init; /* entrypoint for Machine transitions to initial state init */
      
      // don't send the first item
      transition T1
        first init
        then run {
 // pong doesn't send       send IntegerItem(count) via snd;
        }
      
      //get an item, send an item back 
      transition T2
        first run
        accept i : IntegerItem via rcv
        then done {
          assign count := i.value + 1;
          send IntegerItem(count) via snd;
        }
        
    }  // end of  state Machine 
  }  // end of Pong

  part def PingPong {
    doc /* this combines two parts with connections (interfaces) between their ports */
    part ping : Ping;
    part pong : Pong;
    connection ping2pong : IntegerConnection connect ping.snd to pong.rcv;
    connection pong2ping : IntegerConnection connect pong.snd to ping.rcv;
  }  // end of PingPong
    
    case def ExecutionContext {
      subject s : PingPong;
    }
  }
  
  package UnitCaseTest {
    private import Occurrences::*;
    private import UnitCaseModel::*;
    private import VerificationCases::*;
    
    doc
    /*
     * A verification case that executes the "ExecutionContext" from the "UnitCaseModel"
     * and performs a test whether the result meets expectations for the specified 
     * execution rule outlined in the language specification.
     */
     
    verification def ExecutionVerification :> ExecutionContext {
      subject s : PingPong; 
    
      objective {
        verify requirement expectation {
          doc 
          /*
           * Explanation of the expectations during and after execution.
           */
        }
      }
            
      action testExpectation {
        out verdict : VerdictKind;
      }
      first s.endShot then testExpectation;
      
      return verdict : VerdictKind = testExpectation.verdict;
    }
  }  // end of UnitCaseTest
  
// no ExpandedModel 
  
  package ExecutedTraces {
    
    private import Execution::*;
    private import Occurrences::*;
    private import UnitCaseModel::*;
    private import UnitCaseTest::*;

    doc
    /*
     * A model that represents the M0 instantiation of the User's M1 model
     * by using specially annotated model denoting each instance and all of its
     * structural feature values and behavioral steps explicitly stated.  
     * 
     * Note - When instantiating usages, use a consistent naming scheme
     *        that appends a monotonically increasing sequence number 
     *        to the end of the existing name from the unit case model.   
     */
    
    case def Trace :> ExecutionContext {
      subject s : PingPong {
        doc /* PingPong should start, run and stop automatically. */
      }
      
      occurrence TraceValueSlice : ValueSlice {
        :>> that : Trace;
      }
      occurrence TraceBehaviorSlice : BehaviorSlice {
        :>> that : Trace;
      }
      
      // For each feature, create a set of 'TraceValueSlices' that denote 
      // the piecewise time intervals of differing feature values.
      // Note that the timeslices for different features do not need to coincide and can overlap.
      
      timeslice x0 :> TraceValueSlice {
        doc /* entry for both Ping and Pong */
        :>> s.ping.count = 0;
        :>> s.pong.count = 0;
        :>> valueStart = s.ping.Machine.startShot;
        :>> valueEnd = that.pingPongEntry.endShot;
      }
      then timeslice x1 :> TraceValueSlice {
        doc /* init for both Ping and Pong; Ping sends */
        :>> s.ping.count = 0;
        :>> s.pong.count = 0;
        :>> valueStart = that.pingPongEntry.endShot;
        :>> valueEnd = that.pingSends.endShot;
      }
      then timeslice x3 :> TraceValueSlice {
        :>> s.ping.count = 0;
        :>> s.pong.count = 1;
        :>> valueStart = that.pingSends.endShot;
        :>> valueEnd = that.pongReceives.endShot;
      }
      then timeslice x4 :> TraceValueSlice {
        :>> s.ping.count = 2;
        :>> s.pong.count = 1;
        :>> valueStart = that.pingReceives.endShot;
        :>> valueEnd = that.pingPongDone.endShot;
      }
      
      
      timeslice pingPongEntry :> TraceBehaviorSlice {
        :>> activeSteps = (s.ping.Machine.startShot, s.pong.Machine.startShot);
 //       :>> inactiveSteps = (s.ping.Machine.T1, s.pong.Machine.T1, s.ping.Machine.T2, s.pong.Machine.T2);
      }
      then timeslice pingSends :> TraceBehaviorSlice {
        :>> activeSteps = (s.ping.Machine.T1, s.pong.Machine.T1, s.ping2pong.move);
//        :>> inactiveSteps = (s.ping.Machine.T2, s.pong.Machine.T2);
      }
      then timeslice pongReceives :> TraceBehaviorSlice {
        :>> activeSteps = (s.ping.Machine.run, s.pong.Machine.T2, s.pong2ping.move);
      }
      then timeslice pingReceives :> TraceBehaviorSlice {
        :>> activeSteps = (s.ping.Machine.run, s.pong.Machine.endShot);
      }
      then timeslice pingPongDone :> TraceBehaviorSlice {
        :>> activeSteps = (s.ping.Machine.endShot, s.pong.Machine.endShot);
      }
    }
    
    
  }
}

