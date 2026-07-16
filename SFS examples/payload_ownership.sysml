package 'EWG-package-ownership'{
	
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
		flow of PayloadType from left.output.o to right.input.i;
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