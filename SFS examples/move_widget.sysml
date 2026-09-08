package 'move widget' {
  private import Tangibility::Physical;

  item def Widget :> Physical;

  port def MyPort {
    i : Widget;
  }

  action def A {
    action make {
      port o : MyPort;
      send new Widget() via o;
    }
    action get {
      port i : ~MyPort;
      accept myWidget : Widget via i;
    }
    flow moveWidget from make.o to get.i;
    first start then make;
    first make then get;
    first get then done;
  }

  part def FactoryToHome :> Physical {
    part Factory;
    part Truck;
    part Home;
    connect Factory to Truck;
    connect Truck to Home;
  }

  part MoveWidget {
    action a : A;
    part p : FactoryToHome;
    allocate a.make to p.Factory;
    allocate a.moveWidget to p.Truck;
    allocate a.get to p.Home;
  }

}