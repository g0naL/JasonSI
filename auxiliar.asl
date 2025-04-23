/* Initial beliefs and rules */
energy(5).
availableMed(med,medkit).
freeCharguer.

/* Plans */

// Medicine consumption rules

+!toOwnerMed(X,C) : true & startTime(H,M,S,MS) & .time(_,_,_,MS) & medicine(X,Y)
	<-  .wait(1);
		if(C mod (Y + (Y/2)) == 0){
			!go_at(auxiliar,medkit);
			open(medkit);
			-energy(N);
  	        +energy(N-1);
			!spoiledMed(X);
			!toOwnerMed(X,C+1);
		} else{
			if((C + 10) mod Y == 0) {
				!toRobotMed(X);
				!toOwnerMed(X,C+1);
			} else {
				!toOwnerMed(X,C+1);
			};
		}.
		
+!toOwnerMed(X,C) : true & startTime(H,M,S,MS)
	<- !toOwnerMed(X,C).

+!toOwnerMed(X,C) : true & not medicine(X,Y)
	<- .println("There´s no prescription for that medicine").

+!toRobotMed(X) : availableMed(med,medkit)
	<- 	!go_at(auxiliar,medkit);
		open(medkit);
		-energy(N);
  	    +energy(N-1);
		take(med);
		-energy(N);
  	    +energy(N-1);
		close(medkit);
		-energy(N);
  	    +energy(N-1);
		!go_at(auxiliar,robot);
		.print("here´s your ", X, " dear robot");
		.send(robot, achieve, medWalkOwnerWithHelp(X));
		!go_at(auxiliar,fridge).

-!toRobotMed(X) : true & not availableMed(med,medkit) 
	<- !go_at(auxiliar,delivery);
   	   .send(supplier, achieve, order(med,3));
	   .println("I´m asking for more medicines");
	   .wait(5000);
	   .println("I´m picking up the medicines");
	   !go_at(auxiliar,medkit);
	   open(medkit);
	   .println("Meds delivered");
	   close(medkit);
	   +availableMed(med,medkit);
	   !toRobotMed(X).

+!spoiledMed(X) : true & available(med,medkit)
	<- .println(X, " has spoiled!");
		.println("I´m removing ", X, " from the medkit");
		take(med);
		close(medkit);
		!go_at(auxiliar,delivery);
		.println("Putting this spoiled medicine in the trash");
		.send(supplier, achieve, order(med,1));
		.println("I´m asking for more medicines");
	    .wait(5000);
	    .println("I´m picking up the medicines");
	    !go_at(auxiliar,medkit);
	   	open(medkit);
	    .println("Meds delivered");
	    close(medkit);
		!go_at(auxiliar,fridge).
		
-!spoiledMed(X) : true & not availableMed(med,medkit)
	<- .println("Oh, there´s no medicines on the medkit, nothing can spoil").
		
// Medicine modifiers

+!modifyMed(X,P) : true & medicine(X,Y)
	<- -medicine(X,Y);
	   +medicine(X,P).
+!addMed(X,P) : true
	<- +medicine(X,P).
+!removeMed(X) : true & medicine(X,Y)
	<- -medicine(X,Y).
		
// Energy consumption rules
	   
+!energyLooker : energy(N) & N < 20
	<-  !chargue;
		!energyLooker.
+!energyLooker : energy(N) & N > 19
	<- !energyLooker.
+!energyLooker.
	
+!chargue : true & freeCharguer
	<- 	.send(robot,tell,busyCharguer);
		!go_at(auxiliar,charguer);
		.wait(5000);
		-energy(N);
		+energy(100);
		.send(robot,tell,freeCharguer);
		!go_at(auxiliar,fridge).

+!chargue : true & busyCharguer
	<- .println("Waiting for the charguer to be free");
		!chargue.
		
+!busyCharguer : true & freeCharguer
	<- -freeCharguer;
		+busyCharguer.
		
+!freeCharguer : true & busyCharguer
	<- -busyCharguer;
		+freeCharguer.
	   
// Miscellaneous
	   
+!go_at(auxiliar,P) : at(auxiliar,P) <- true.
+!go_at(auxiliar,P) : not at(auxiliar,P) & energy(N) & N > 0
  <- posibility(P,N); 
  	 move_towards(P);
     -energy(N);
  	 +energy(N-1);
     !go_at(auxiliar,P).
	 
-!go_at(auxiliar,P) : true
	<-	!chargue;
		!go_at(auxiliar,P).
	   
+stock(med,0)
   :  availableMed(med,medkit)
   <- -availableMed(med,medkit).
+stock(med,N)
   :  N > 0 & not available(med,medkit)
   <- -+available(med,medkit). 

+delivered(med,_Qtd,_OrderId)[source(supplier)]
  :  true
  <- +availableMed(med,medkit).

