package SFS {

private import Interfaces::BinaryInterface;
private import FlowConnections::FlowConnection;
private import AADL::DataPort;

  interface def DataPortConnection :> BinaryInterface {
      flow move : FlowConnection {
        end occurrence source : DataPort :>> source = BinaryInterface::source;
        end occurrence target : DataPort :>> target = BinaryInterface::target;
      }
  }


}