//multicast.sysml

package multicast {
  doc /* virtual payloads can multicast */
  private import Tangibility::Virtual;
  private import Interfaces::BinaryInterface;
  private import Flows::Flow;

  item def DataPayload :> Virtual {
    value : Base::DataValue;
  }

  port def P {
    out itm : DataPayload;
  }

  interface def I :> BinaryInterface {
    end source : P :> source;
    end target : ~P :> target; 
    
    flow move : Flow {
        end occurrence source : DataPayload :>> source, Flows::flows::source ::> I::source.itm;
        end occurrence target : DataPayload :>> target, Flows::flows::target ::> I::target.itm;
      }
  }

  part c {
    action sender {
      port o : P;
      ref item v : DataPayload := new DataPayload(5);
      send v via o.itm;
    }
    action r1 {
      port i : ~P;
      ref item v1 : DataPayload;
      accept v1 : DataPayload via i.itm;
    }
    action r2 {
      port i : ~P;
      ref item v2 : DataPayload;
      accept v2 : DataPayload via i.itm;
    }
    interface i1 : I connect sender.o to r1.i;
    interface i2 : I connect sender.o to r2.i;
  }
}