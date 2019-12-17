set wms(console) 0
if {$wms(console)} {
  console show
}

set wms(active) 0
set wms(temp) 0
set wms(zndjntctr) 0

set wms(zond) {}

set wms(port) {}
set wms(startmeas) 0

set wms(calculate) 0

# DB connect variables
set wms(connect) 0
set wms(maxid) 0

set wms(lamda,old,blu) 420000
set wms(lamda,old,red) 660000

set wms(repeat) 1

set wms(tolerance) 2
set wms(sensetivity) 7
set wms(calibr) 7

set wms(DELTAI)  7
set wms(EPSI)  5

set wms(STATUS)  {514 0 0 0 0 0}

set wms(COMPATH)  "./"
set wms(CURPATH)  "./"

set wms(GRAPH) 1
set wms(PRESET_W) 1

set wms(com) {}
set wms(mnlist) {}

set wms(dae) "[clock format [clock seconds] -format "%y%m%d"]00"
set wms(data) "[clock format [clock seconds] -format "%y%m%d"]"

set wms(sph) 0

set wms(avermeas) 10

set wms(lst) {0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z}

set wms(pause) 0
set wms(pause,cnt) 0
set wms(ready) 1

set wms(S01,Dens) 0.4
set wms(S02,Dens) 0.162

set wms(S01,Xo) 0
set wms(S02,Xo) 0

set wms(S01,HB) 700
set wms(S02,HB) 700

set wms(S01,L) 25
set wms(S02,L) 35

set wms(S01,RWI) 589
set wms(S02,RWI) 739.4

set wms(S01,RTI) 568
set wms(S02,RTI) 705

set wms(S01,RC) 364
set wms(S02,RC) 455

set wms(S01,RH) 271
set wms(S02,RH) 273

set wms(S01,ALFAI) -5
set wms(S02,ALFAI) -39

set wms(S01,TEMPA) 0.0588
set wms(S02,TEMPA) 0.059924

set wms(S01,TEMPB) 5e-06
set wms(S02,TEMPB) 3.51e-05

set wms(S01,TEMPC) 0.0445
set wms(S02,TEMPC) 0.0004

#SM
set wms(stat) "Ready"
set wms(sm) 0
set wms(vix) 1
set wms(zondinit) 0
set wms(zond,fail) 0
set wms(zond,stop) 0

set wms(tempaver) 1


  set wms(1,net,swms)  "192.168.0.123"
  set wms(1,port,swms) "4003"
  set wms(1,port,adam) "4004"
  set wms(1,adr,adam)  1

  set wms(2,net,swms)  "192.168.0.124"
  set wms(2,port,swms) "4003"
  set wms(2,port,adam) "4004"
  set wms(2,adr,adam)  2


  foreach adrDev {1 2} {

    set wms($adrDev,swms,IntTime) 8
    set wms($adrDev,swms,PixMode) 0
    set wms($adrDev,swms,lamda) {}
  }

set cnt 0

set adrDev 1

set wms(hostname) [info hostname]

set wms(tt_adr_list) {localhost 192.168.0.101 192.168.0.102 192.168.0.103}

if {$wms(hostname) == "td16003"} {
  set wms(adr_tt) "192.168.0.101"
} elseif {$wms(hostname) == "td15003"} {
  set wms(adr_tt) "192.168.0.101"
} elseif {$wms(hostname) == "tn12001"} {
  set wms(adr_tt) "192.168.0.101"
} else {
  set wms(adr_tt) "localhost"
}


foreach name {S01 S02} {

  set wms($name,new_meth) 1
  set wms($name,meth) "M3"
  set wms($name,Io1) 1
  set wms($name,Io2) 0
  set wms($name,coord_in_tube) 2

  set wms($name,adrDev) $adrDev

  set wms($name,swms,lamda) {}
  set wms($name,adr,moxa)  "192.168.0.123"
  set wms($name,port,swms) "4003"
  set wms($name,port,adam) "4004"
  set wms($name,adr,adam)  1

  set wms($name,swms,IntTime) 8
  set wms($name,swms,PixMode) 0

  set wms($name,string) ""
  set wms($name,cmd)    ""

  set wms($name,2w,blu) 420000
  set wms($name,2w,red) 660000

  set wms($name,corIo) 0
  set wms($name,l,uv) 300000
  set wms($name,l,ir) 900000
  set wms($name,npoints) 100

  set wms($name,type) swms
  set wms($name,active) 0

  set wms($name,firstpoint) 1

  set wms($name,mpnts) 0

  set wms($name,tr_off) 0
  set wms($name,ang_off) 0

  set wms($name,swms,sortchlst) {1}

  incr cnt
  incr adrDev
}


  set wms(error) 0
  set wms(info) {}