//generated from VVI.aadl


package vvi_mode {
  doc 
  /* 
   * VVI is a single chamber mode of pacing by implanted pacemakers.
   * VVI modes causes a 'pace' to cause heart contraction, when intrinsic heart rate
   * is below prescribed Lower Rate Limit
   */
  private import IPI::*;
  private import ISQBase::DurationValue;
//  private import Time::TimeInstantValue;
  private import ScalarValues::NumericalValue;
  private import Assert::Assert;
  private import Assert::Invariant;
  private import States::StateAction;

//first define the item sent/received by a port by specializing AadlData
//and redining its "value" attribute to desired data type  
  item def DurationItem :> AadlData {
    attribute value : ISQBase::DurationValue redefines value;
  }

//second define the port, redefining its "itm" to your item  
  port def DurationPort :> DataPort {
    out item itm : DurationItem redefines itm;
  }

//third define the interface which connects your ports  
  interface def DurationConnection :> DataConnection {
    end source : DurationPort redefines source;
    end target : ~DurationPort redefines target;
  }

//states in BLESS (or BA) must be intial, final, complete , or execution
  enum def StateKind {
    initial; final; complete; execution;
  }  
  state def BlessState :> StateAction {
     kind : StateKind;
  }

//AADL threads are state machines which interact through ports  
	part def VVI :> AADL::Thread {
	  doc
	  /*
	   * State-transition machine implementing VVI function.
	   */
		port lrl : ~DurationPort {  // conjugate for 'in' port
		  doc /* Lower Rate Limit Interval ~1000 ms */
		}

    port vrp : ~DurationPort { // conjugate for 'in' port
		  doc /* Ventricular Refractory Period ~250 ms */
		}

		port s : ~AADL::EventPort { // conjugate for 'in' port 
		  doc /* sense signal from analog front end */
		}
		  
		port p : AADL::EventPort {
		  doc /* pace event to analog front end to issue ~2V, 400 us pace to heart */
      @Assert { f = "VP()"; }
    }
      
		port n : AADL::EventPort {
		  doc /* non-refractory ventricular sense, intrinsic heart beat */
      @Assert { f = "VS()";}
		}
		
		port h : ~AADL::EventPort {
		  doc /* turn off */
		}
		
		// variables
		attribute last_beat : NumericalValue;  //Time::TimeInstantValue;
		
		state VVIStates {
		  doc /* State-transition machines must be in a state definition. */
		  @Assert {f = ("notVRP: : (n or p)@last_beat and ((now-last_beat)>=vrp)",
		    "VS: : s@now and notVRP()",
		    "VP: : --cause ventricular pace
          (n or p)@(now-lrl)  --last beat occurred LRL interval ago,
          and --not since then
          not (exists t~time  --there is no time  
            in (now-lrl),,now  --since then, 
            that (n or p)@t)   --with a beat",
        "PACE:x~time: --pace occurred in the previous LRL interval
            p@last_beat and  --previous beat was a pace
            (exists t~time  --there is a time 
              in (x-lrl)..x  --in the previous LRL interval 
              that p@t)   --with a ventricular pace",
        "SENSE:x~time:  --sense occurred in the previous LRL interval
            n@last_beat and  --previous beat was a sense
            (exists t~time  --there is a time 
              in (x-lrl)..x  --in the previous LRL interval
              that n@t)   --with a non-refractory sense");
		  }
		  @Invariant {inv = "LRL: : --Lower Rate Limit
            exists t~time  --there was a moment
              in (now-lrl)..now   --within the previous LRL interval
              that (n@t or p@t)   --with a pace or non-refractory sense";}
 		  
		  
  		state powerOn : BlessState {  /* initial */
  		  :>> kind := StateKind::initial;
        @Assert {f = "now = 0.0 s"; } }
      state pace : BlessState {  /* complete */
        :>> kind := StateKind::complete;
        @Assert {f = "PACE(now)"; } }
      state sense : BlessState {  /* complete */
        :>> kind := StateKind::complete;
        @Assert {f = "SENSE(now)"; } }
      state check_pace_vrp : BlessState { /* execution */
        :>> kind := StateKind::execution;
        @Assert {f = "s@now and PACE(now)"; } }
      state check_sense_vrp : BlessState { /* execution */
        :>> kind := StateKind::execution;
        @Assert {f = "s@now and SENSE(now)"; } }
	  	state off : BlessState {  /* final */ 
        :>> kind := StateKind::final;	}
		
	  	entry; then powerOn; /* entrypoint for VVIStates transitions to initial state powerOn */
		
		  transition T1_POWER_ON 
		    first powerOn 
		    then sense { 
            @Assert {f = "now = 0.0 s"; }
		      send AadlEvent() via n {  
            @Assert {f = "n@now"; } }
          assign last_beat := localClock.currentTime {
            @Assert {f = "last_beat=now"; } }
        }
              
      transition T2_STOP_pace
        first pace
        accept e : AadlEvent via h
        then off;
              
      transition T2_STOP_sense
        first sense
        accept e : AadlEvent via h
        then off;
      
      transition T3_PACE_LRL_AFTER_VP
        first pace
        accept when last_beat + lrl.itm.value <= localClock.currentTime
        then pace { 
            @Assert {f = "VP()"; }
          send AadlEvent() via p {  
            @Assert {f = "p@now"; } } 
          assign last_beat := localClock.currentTime {
            @Assert {f = "last_beat=now and p@now"; } } 
        }
        
      transition T4_VS_AFTER_VP
        first pace
        accept e: AadlEvent via s
        then check_pace_vrp;  
          
      transition T5_VS_AFTER_VP_IN_VRP
        first check_pace_vrp 
        accept when localClock.currentTime - last_beat < vrp.itm.value
        then pace;
          
      transition T6_VS_AFTER_VP_IS_NR
        first check_pace_vrp 
        accept when localClock.currentTime - last_beat >= vrp.itm.value
        then sense { 
            @Assert {f = "VS()"; }
          send AadlEvent() via n {  
            @Assert {f = "n@now"; } } 
          assign last_beat := localClock.currentTime {
            @Assert {f = "last_beat=now and n@now"; } }
        }
        
      transition T7_PACE_LRL_AFTER_VS
        first check_pace_vrp
        accept when last_beat + lrl.itm.value <= localClock.currentTime
        then pace { 
            @Assert {f = "VP()"; } 
          send AadlEvent() via p {  
            @Assert {f = "p@now"; } }
          assign last_beat := localClock.currentTime {
            @Assert {f = "last_beat=now and p@now"; } }
        }
        
      transition T8_VS_AFTER_VS
        first sense
        accept e: AadlEvent via s
        then check_sense_vrp;  
          
      transition T9_VS_AFTER_VS_IN_VRP
        first check_sense_vrp 
        accept when localClock.currentTime - last_beat >= vrp.itm.value
        then sense;
        
      transition T10_VS_AFTER_VS_IS_NR
        first check_sense_vrp
        accept when last_beat + lrl.itm.value <= localClock.currentTime
        then pace { 
            @Assert {f = "VS()"; }
          send AadlEvent() via n {  
            @Assert {f = "n@now"; } }
          assign last_beat := localClock.currentTime {
            @Assert {f = "last_beat=now and n@now"; } }
        }
                  
		}  //end of VVIStates
	}  //end of VVI thread

	part def 'VVI.i' :> VVI;

	part def RateControl :> AADL::Thread {
		port lrl : DurationPort;

		port vrp : DurationPort; 

		attribute :>> Period = 10 [SI::s];
	}

	part def PG :> AADL::System {
		port lead : AADL::BusAccess {
			in ref :>> type : vvi_mode::IS1;
		}
	}

	part def 'PG.i' :> PG {
		part fe : vvi_mode::FrontEnd;
		part pp : 'PGprocess.i';
		connection header : AADL::FeatureConnection connect fe.lead to lead;
		connection sense : EventConnection connect fe.sense to pp.sense;
		connection pace : EventConnection connect pp.pace to fe.pace;
	}

	part def PGprocess :> AADL::Process {
		port sense : AADL::EventPort;
		port pace : AADL::EventPort;
	}

	part def 'PGprocess.i' :> PGprocess {
		part t : 'VVI.i';
		part rc : vvi_mode::RateControl;
    connection lrl : DurationConnection connect rc.lrl to t.lrl;
    connection vrp : DurationConnection connect rc.vrp to t.vrp;
		connection s : EventConnection connect sense to t.s;
		connection p : EventConnection connect t.p to pace;
		connection l : EventConnection connect rc.lrl to t.lrl;
		connection v : EventConnection connect rc.vrp to t.vrp;
	}

	part def FrontEnd :> AADL::Device {
		port sense : AADL::EventPort;
		port pace : AADL::EventPort;

		port lead : AADL::BusAccess {
			in ref :>> type : vvi_mode::IS1;
		}
	}

	part def IS1 :> AADL::Bus;

	part def Patient :> AADL::Abstract {
		port lead : AADL::BusAccess {
			in ref :>> type : vvi_mode::IS1;
		}
	}

	part def Implant :> AADL::System;

	part def 'Implant.i' :> Implant {
		part patient : vvi_mode::Patient;
		part lead : vvi_mode::IS1;
		part pacemaker : 'PG.i';
		binding toPatient : AADL::FeatureConnection bind lead = patient.lead.type;
		binding toPG : AADL::FeatureConnection bind lead = pacemaker.lead.type;
	}

	part def CardiacDuration :> AADL::Data;
}