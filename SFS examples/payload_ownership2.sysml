package 'EWG-package-ownership-2'{
	doc /*
	* Variant of payload_ownership.sysml that closes the gap flagged in that file's own
	* doc comment: instead of a plain port-item assignment (action outport assign
	* output.o := pt;), left sends its payload with an explicit send action, and right
	* receives it with an explicit accept action. No ports or declarative flow are
	* needed — send/accept route directly between occurrences (see SFS examples/
	* send_accept.sysml for the base idiom).
	*
	* This ties the transfer formally into the buffer-based Transfer semantics:
	* Transfers::SendPerformance (Transfers.kerml:277-300) explicitly calls
	* sender.outgoingBuffer.put before transferring, and Transfers::AcceptPerformance
	* (Transfers.kerml:319-356) explicitly waits on and evicts from
	* receiver.incomingBuffer — unlike a plain assignment, which is untied to any
	* buffer load (AssignmentAction :> SetNow, //FeatureWritePerformance —
	* Actions.sysml:389).
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
				action sendIt {
					send pt to right;
				}

				first wait then remove;
				first remove then sendIt;
			}
		}
		part right : PartType {
			:>> x = 2;

			item q : PayloadType [0..1] := null;

			perform action doIt {
				accept q : PayloadType;
			}
		}
	}

	verification 'payload ownership 2'{
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
