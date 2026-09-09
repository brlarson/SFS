package 'perform wrong' {
  private import Tangibility::Physical;

  item def MyItem;

  action A {
    action a1 {
      out i : MyItem;
      assign i := new MyItem();
    }
    action a2 {
      in i : MyItem;
    }
    bind a1.i = a2.i;
    first start then a1;
    first a1 then a2;
    first a2 then done;
  }

  part P : Physical{
    part p1 {
      perform A.a1;
    }
    part p2 {
      perform A.a2;
    }
  }
}