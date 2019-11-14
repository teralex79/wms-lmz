proc StartMeas {} {
global wms meas

  set wms(nwms,ready) 1

  foreach name $wms(zond) {
    if {$wms($name,firstpoint)==1} {
      set wms($name,head_file) 0
    }

    set wms($name,tr,next)  [lindex $wms($name,tr)  [expr {$wms($name,firstpoint) - 1}]]
    set wms($name,ang,next) [lindex $wms($name,ang) [expr {$wms($name,firstpoint) - 1}]]

    set wms($name,smstat) "meas"

    if {$wms($name,type)=="nwms"} {
      set wms($name,colorlist) ""
      foreach color $wms(colorlist) {
        if {$meas($name,$color)} {
          lappend wms($name,colorlist) $color
        }
      }
    }
    set wms($name,busytemp) 0
  }

  set wms(finmeas)   0
  set wms(zond,fail) 0
  set wms(zond,stop) 0
  set wms(pause)     0
  set wms(busytemp)  0

  ConfPause 0
  
  foreach name $wms(zond) {
    if {!$wms(zndjntctr)} {
      set answ [tk_messageBox -message "Проверить, что зонд $name разведен?" -title "Question $name" -type yesno -icon question]
      if {$answ=="yes"} {
        set wms($name,done) 0
        if {$wms($name,type)=="nwms"} {
          CheckZondNWMS $name 0 0
        } else {
          CheckZond $name [format "%02X" $wms($name,adr,adam)] 0
        }
        if {!$wms($name,done)} {
          vwait wms($name,done)
        }
        if {$wms($name,state,current)=="сведен"} {
          set answ [tk_messageBox -message "Зонд сведен, развести зонд $name" -title "Question $name" -type yesno -icon question]
          if {$answ=="yes"} {
            set wms($name,done) 0
            set wms(zndjntctr) 1

            ZondContrAdam 0 $name

            set wms(zndjntctr) 0
            if {!$wms($name,done)} {
              vwait wms($name,done)
            }
          }
        }
      }
    }
  }

  set wms(startmeas) 1
  foreach name $wms(zond) {
    after 50 MoveZond $name
  }
}

proc ConfPause {pause} {
global wms

  set wms(pause,cnt) 0

  if {$pause==1} {

    set wms(startmeas) 0
    set txt "Продолжить"
    set cmd "StartMeas"
    set state active
  } else {

    set txt "Пауза"
    set cmd "set wms(pause,cnt) 0; set wms(pause) 1;.fr1.com.startlf.bt1 configure -state disabled"
    set state disabled
  }

## Perekonf-tsija knopki Pauza v knopku Prodolzhit'

  .fr1.com.startlf.bt1 configure -text $txt -command "$cmd" -state active

  foreach name $wms(zond) {

    .fr1.zond.bottombt$name.bt1 configure -state $state
    .fr1.zond.bottombt$name.bt2 configure -state $state
  }
  update
}

proc MoveZond {name} {
global wms

  set wms($name,I,Spectrum) ""
  if {$wms($name,Io1) || $wms($name,Io2) || $wms($name,tr,next)<10} {
    set wms($name,Io1,Spectrum) ""
    set wms($name,Io2,Spectrum) ""
  }

  set wms($name,tr,current)  $wms($name,tr,next)
  set wms($name,ang,current) $wms($name,ang,next)
  set wms($name,nomove,tr)    1
  set wms($name,nomove,ang)   1
  update

  after 100 MeasFullWet $name 1 1
}

proc MeasFullWet {name join rep} {
global wms

  if {!$wms(pause) || [expr {$wms(pause) && $join!=1}] || [expr {$wms(pause) && $rep!=1}]} {

    set n $wms($name,firstpoint)
    set wms($name,tr,next)  [lindex $wms($name,tr) $n]
    set wms($name,ang,next) [lindex $wms($name,ang) $n]

    set wms($name,cont) 0

    if {$wms(temp)} {
      if {$join==1} {
        if {$wms(busytemp)} {vwait wms(busytemp)}
    
        set wms(busytemp) 1
        set wms($name,busytemp) 1
        set wms($name,repeat) $rep
        MeasTemp $name $n $rep $wms(tempaver)
        if {$wms(busytemp)} {vwait wms(busytemp)}
      }
    } else {
      set wms($name,temp,$n) 0
    }

    if {$wms($name,wet,$n) && !$wms($name,nowet)} {
      if {$join!=0} {
        if {($join==1 && $wms($name,Io1)) || ($join==2 && $wms($name,Io2))} {

          set wms($name,state,next) "Свести"
        }
      } else {

        set wms($name,state,next) "Развести"
      }

      set wms($name,done) 0

      ZondContrAdam $join $name

      if {!$wms($name,done)} {
        vwait wms($name,done)
      }

      set wms($name,t1,$join) [clock clicks -milliseconds]

      after 50
      MeasWet $name $join $n
    } else {
      set wms($name,cont) 1
    }
    set wms($name,cnt) 1
    ContMeas $name $join $n $rep
  } else {

    incr wms(pause,cnt)
    if {$wms(pause,cnt)==[expr {[llength $wms(zond)] - $wms(finmeas)}]} {
      ConfPause 1
    }
  }
}

proc ContMeas {name join n rep} {
global wms meas
puts "ContMeas $name $join $n $rep"
  if {$wms($name,cont)<1} {
    if {$wms($name,cnt)} {
       set wms($name,cnt) 0
      .fr1.zond.type$name configure -fg green
    } else {
       set wms($name,cnt) 1
      .fr1.zond.type$name configure -fg black
    }
    after 200 ContMeas $name $join $n $rep
  } else {

    .fr1.zond.type$name configure -fg black
    if {$join==1} {
      after 5
      MeasFullWet $name 0 $rep
    } elseif {$join==0} {
      after 5
      MeasFullWet $name 2 $rep
    } else {

      if {$wms($name,busytemp)} {vwait wms($name,busytemp)}
      set wms($name,t) $wms($name,temp,$n)

      SaveWMSFile $name $n $rep

      if {$rep>=$wms(repeat)} {

        incr wms($name,points) -1
        incr wms($name,firstpoint)
        update

        if {$wms($name,points)<=0} {

          set wms($name,points) "finish"
          set wms($name,smstat) "finish"
          incr wms(finmeas)

          if {$wms(zndjntctr)} {
            set flag 0
            if {!$wms($name,Io1)} {
              set flag 1
              set wms($name,Io1) 1
            }
            set wms($name,state,next) "Свести"

            ZondContrAdam 1 $name

            if {$flag} {
              set wms($name,Io1) 0
            }
          }

          if {$wms(finmeas)==[llength $wms(zond)]} {
            FinishMeas
          } else {
            if {$wms(pause,cnt)==[expr {[llength $wms(zond)] - $wms(finmeas)}]} {
              ConfPause 1
            }
          }
        } else {
          if {$wms(zond,fail) || $wms(zond,stop)} {

            incr wms(pause,cnt)
            if {$wms(pause,cnt)==[expr {[llength $wms(zond)] - $wms(finmeas)}]} {
              ConfPause 1
            }
          } else {
#            set wms(pause,cnt) 0
            set wms(pause) 1
            .fr1.com.startlf.bt1 configure -state disabled
            after 10 MoveZond $name
          }
        }
      } else {
        incr rep
        MeasFullWet $name 1 $rep
      }
    }
  }
}

proc MeasWet {name join n} {
global wms

  if {!$join || ($join==1 && $wms($name,Io1)) || ($join==2 && $wms($name,Io2))} {
    Meas_SWMS $name $join $n
  } else {
    incr wms($name,cont)
  }
}

proc MeasCoef {} {
global wms

  if {$wms(zndjntctr)} {

    set wms(startmeas) 0

    .fr1.com.startlf.bt1 configure -state disabled
    update

    foreach name $wms(zond) {
      .fr1.zond.bottombt$name.bt1 configure -state disabled
      .fr1.zond.bottombt$name.bt2 configure -state disabled
    }

    foreach name $wms(zond) {
      if {$wms($name,active)} {
        set flag 0
        if {!$wms($name,Io1)} {
          set flag 1
          set wms($name,Io1) 1
        }

        MeasCoefSWMS $name
        SaveCoef $name

        set wms($name,state,next) "Свести"

        ZondContrAdam 1 $name

        if {$flag} {
          set wms($name,Io1) 0
        }
      }
    }

    .fr1.com.startlf.bt1 configure -state active

    foreach name $wms(zond) {
      .fr1.zond.bottombt$name.bt1 configure -state active
      .fr1.zond.bottombt$name.bt2 configure -state active
    }
  } else {
    foreach name $wms(zond) {
      if {$wms($name,active)} {
        foreach lamda $wms($name,swms,lamda) {
          set wms($name,coef,$lamda) 1.0
        }
      }
    }
  }
}

proc MeasCoefSWMS {name} {
global wms

  set wms($name,I,Spectrum) ""
  set wms($name,Io1,Spectrum) ""
  set wms($name,Io2,Spectrum) ""

  set wms($name,cont) 0

  set wms($name,done) 0
  set wms($name,state,next) "Свести"
  ZondContrAdam 1 $name

  if {!$wms($name,done)} {
    vwait wms($name,done)
  }

  Meas_SWMS $name 1 k

  set wms($name,done) 0
  set wms($name,state,next) "Развести"
  ZondContrAdam 0 $name

  if {!$wms($name,done)} {
    vwait wms($name,done)
  }
  Meas_SWMS $name 0 k

  set cnt 0
  foreach lamda $wms($name,swms,lamda) {
    if {$wms(active)} {
      set Ip [lindex $wms($name,swms,Icalc,k,0) $cnt]
      set Ic [lindex $wms($name,swms,Icalc,k,1) $cnt]
    } else {
      set Ip 0
      set Ic 0
    }
    if {$Ip>0 && $Ic>0} {
      set wms($name,coef,$lamda) [format "%6.4f" [expr {1.*$Ip/$Ic}]]
    } else {
      set wms($name,coef,$lamda) 1.0
    }
    incr cnt
  }
}

proc FinishMeas {} {
global wms meas

  foreach name $wms(zond) {
    if {$wms(calculate)} {
      FormOldWMS   $name "$wms(DATAPATH)/$wms(dae)/$wms(mn)/${name}"
      ReadRAW_Disp $name "$wms(DATAPATH)/$wms(dae)/$wms(mn)/${name}"
    }
  }

  tk_messageBox -message "Measure Finish" -title "Traverse finish" -type ok -icon info

  set wms(startmeas) 0
  foreach name $wms(zond) {

    set wms($name,I,Spectrum) ""
    set wms($name,Io1,Spectrum) ""
    set wms($name,Io2,Spectrum) ""
    
    set wms($name,firstpoint) 1
    set wms($name,colorlist) {}
    set wms($name,t) ""

    set wms($name,state,next) "Свести"
    set wms($name,done) 0

    ZondContrAdam 1 $name

    if {!$wms($name,done)} {
      vwait wms($name,done)
    }
    ReadRWV $name
  }

  FindMeasDate
  set wms(mpoint) 0
  set wms(zondinit) 0

  .fr1.com.startlf.bt1 configure -text "Старт" -command "StartMeas" -state active

  foreach name $wms(zond) {
    .fr1.zond.bottombt$name.bt1 configure -state active
    .fr1.zond.bottombt$name.bt2 configure -state active
  }
}
