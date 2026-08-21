package 'EWG-package-ownership'{
	doc /*
	* Claude-Hypha found an interesting gap using the SFS sysml.library.
	Essentially, just asigning to an item in a port is not enough to cause the transfer.
	On line 86 of payload_ownership.sysml:

flow :Flows::Flow of PayloadType from left.output.o to right.input.i;

This declares an (unnamed) flow usage typed by Flows::Flow, restricted to PayloadType payloads, with left.output.o bound as the 
flow's source end and right.input.i as its target end.

Type chain that does the actual moving (Flows.sysml:76-119, Transfers.kerml):

Flow :> Message :> MessageAction, Transfer and Flow :> ... FlowTransfer. All the executable machinery lives on the base Transfer 
interaction (Transfers.kerml:25-100), which chains three steps via succession:

1. getPayloadFromSource: source.outgoingBuffer.get (Transfers.kerml:78) — pulls a value out of left.output.o's own outgoingBuffer.
2. delay: TriggerAfter using transferDuration (default 0 [s]) (Transfers.kerml:82).
3. putPayloadToTarget: target.incomingBuffer.put (Transfers.kerml:87) — pushes that value into right.input.i's incomingBuffer.

source/target are Occurrence, and every Occurrence carries its own incomingBuffer/outgoingBuffer (var feature ... : Buffer) as an 
SFS addition — Occurrences.kerml:847,849, replacing the old sourceOutput/targetInput features (see the //SFS comments at 
Transfers.kerml:37,46). o and i are item features, hence themselves Occurrences, so they each get their own FIFO Buffer 
(get/put/evict defined in the SFS-added RunTimeServices.kerml). FlowTransfer's own isMove/isPush flags and the connectors that 
would formally enforce them are commented out (Transfers.kerml:160-184), so they're documentation only — the real mechanics are 
just this generic get→delay→put chain, common to every Transfer (sends/accepts included).

One gap worth flagging: left's doIt action populates output.o with action outport assign output.o := pt; (line 62) — a plain 
AssignmentAction/FeatureWritePerformance, which just sets the current value of the feature. Nothing in this model explicitly 
calls output.o.outgoingBuffer.put. Contrast with Transfers::SendPerformance (Transfers.kerml:277-300), which does explicitly 
sender.outgoingBuffer.put before transferring. So strictly by the buffer-based Transfer semantics now in this library, it isn't 
formally shown that assigning output.o := pt loads o's outgoingBuffer — the example (and its sibling flow_out_to_in.sysml in 
SFS examples/, whose doc comment still describes the pre-refactor sourceOutput/targetInput model) is relying on an informal 
identification of "the port item's current value" with "what's in its outgoing buffer" that isn't spelled out anywhere in KerML text.
	*/
	private import Occurrences::*;
	private import ScalarValues::*;
	private import ISQ::*;
	private import SI::*;
	private import VerificationCases::*;
	private import Triggers::*;
	private import ISQBase::DurationValue;
	
	part def PartType {
		attribute x : Integer;
	}
	
	part def PayloadType {
		attribute currentValue : Integer [0..1];
		action recordValue {
			loop {
				action wait subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerAfter(1 [s], receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				// loop every so often and capture the value
				
				// Note - "owner" for composite features is "Occurrence.superoccurrence" and NOT always "this.that"
				// "that" does not require composition (Ed)
				// "superoccurrence" implies composition
				action update assign currentValue := ((this as Occurrence).superoccurrence as PartType).x;
				
				first wait then update;
			}
		}
		perform action a ::> recordValue;
	}
	
	part def Context :> PartType {
		:>> x = 0;
		
		part left [1] : PartType {
			:>> x = 1;
			
			port output{
				out item o : PayloadType [0..1];
			}
			
			// There is nothing to say this composite feature would have its value removed!
			item p : PayloadType [0..1] := new PayloadType();
			
			perform action doIt {
				// Using a ref item as part of the action would ensure that
				// no composite instance would be left at the source after transfer.
				ref item pt : PayloadType [1] = p;
				
				action wait subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerAfter(2 [s], receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				// We would need to remove the value from 'p' manually
				// to ensure there would be no issues with a race condition
				// indicating two competing owners.
				action remove assign p := null;
				action outport assign output.o := pt;
				
				first wait then remove;
				first remove then outport;
			}
		}
		part right : PartType {
			:>> x = 2;
			
			port input {
				in item i : PayloadType [0..1];
			}
			item q : PayloadType [0..1] := null;
			
			perform action doIt {
				action wait subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerAfter(5 [s], receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				action inport assign q := input.i;
				
				first wait then inport;
			}
		}
		flow :Flows::Flow of PayloadType from left.output.o to right.input.i;
	}
	
	verification 'payload ownership'{
		subject subj : Context;
		
		attribute value1 : Integer [0..1];
		attribute value2 : Integer [0..1];
		
		action test {
			action wait1 {
				action a subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerWhen({ subj.left.p != null }, receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
					// wait to give 'q' time to capture the last value
				action b subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerAfter(2.0 [s], receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				first a then b;
			}
			action capture1 assign value1 := subj.left.p.currentValue;
			action wait2 {
				// wait until 'q' has a value
				action a subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerWhen({ subj.right.q != null }, receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				// wait to give 'q' time to capture the last value
				action b subsets Actions::Action::acceptSubactions {
					in ref redefines Actions::AcceptAction::payload = Triggers::TriggerAfter(2.0 [s], receiver);
					in ref redefines Actions::AcceptAction::receiver = this;
				}
				first a then b;
			}
			action capture2 assign value2 := subj.right.q.currentValue;
			
			first wait1 then capture1;
			first capture1 then wait2;
			first wait2 then capture2;
		}
		
		return verdict : VerdictKind = PassIf(value1 == 1 and value2 == 2);
	}
}