proc FillHeadSWMS {name} {
global wms

  set wms($name,head_file) 1

  set ctime [clock seconds]
  set date [clock format [clock seconds] -format "%y_%m_%d"]

  catch [file mkdir $wms(data_path)/$wms(dae)/$wms(mn)/${name}]

  set log [open $wms(data_path)/$wms(dae)/$wms(mn)/${name}/${name}_swms.txt "w"]

  puts -nonewline $log "Дата: ${date}; "
  puts -nonewline $log "Имя_режима: $wms(dae); "
  puts -nonewline $log "Имя_замера: $wms(mn); "
  puts -nonewline $log "Имя_зонда: $name; "
  puts -nonewline $log "Тип Модуля: $wms($name,type) "

  puts -nonewline $log "$wms($name,swms,SName)"
  puts $log ""
  puts $log ""

  foreach par {RWI RTI RC RH ALFAI} {

    puts -nonewline $log "$par=$wms($name,$par); "
  }
  puts -nonewline $log "red=$wms($name,2w,red); "
  puts -nonewline $log "blu=$wms($name,2w,blu); "
  puts $log ""
  puts $log ""

  puts -nonewline $log "NewMeth=$wms($name,new_meth); "
  puts $log ""
  puts $log ""

  puts -nonewline $log "XinTube=$wms($name,coord_in_tube); "
  puts $log ""
  puts $log ""

  puts -nonewline $log "Join=$wms($name,Io1)$wms($name,Io2) (Iсв1,Iсв2); "
  puts -nonewline $log "L(мм)=$wms($name,L); "
  puts -nonewline $log "repeat=$wms(repeat); "
  puts -nonewline $log "PixMode=$wms($name,swms,PixMode); "
  puts -nonewline $log "IntTime(мс)=$wms($name,swms,IntTime); "

  foreach item {l0 l1 l2 l3 slc nlcc0 nlcc1 nlcc2 nlcc3 nlcc4 nlcc5 nlcc6 nlcc7 pnlc} {
    puts -nonewline $log "$item=$wms($name,swms,$item); "
  }
  puts $log ""
  puts $log ""

  foreach lamda $wms($name,swms,lamda) {
    if {$wms($name,Io1) || $wms($name,Io2)} {
      set coef $wms($name,coef,$lamda)
    } else {
      set coef 1.0000
    }
    puts -nonewline $log "K($lamda)=$coef; "
  }
  puts $log ""
  puts $log ""

  puts -nonewline $log "hh:mm:ss"
  puts -nonewline $log "[format "%4s" N]"
  puts -nonewline $log "[format "%2s" n]"
  puts -nonewline $log "[format "%7s" X]"
  puts -nonewline $log "[format "%7s" Y]"
  if {$name!="A1" && $name!="A2"} {
    puts -nonewline $log "[format "%8s" RadP(W)]"
    puts -nonewline $log "[format "%8s" RadP(T)]"
  }
  puts -nonewline $log "[format "%7s" Dens]"
  puts -nonewline $log "[format "%5s" Join]"
  puts -nonewline $log "[format "%7s" Type]"
  puts -nonewline $log "[format "%7s" T,C]"

  foreach lamda $wms($name,swms,lamda) {
    puts -nonewline $log "[format "%8d" $lamda]"
  }

  puts $log ""
  puts $log ""

  close $log
}

proc SaveFileSWMS {name n i} {
global wms a

  if {!$n} {

    set x 0
    set y 0
    set dens 0
  } else {

    set x $wms($name,tr,current)
    set y $wms($name,ang,current)
    set dens [lindex $wms($name,dens_l) [expr {$n-1}]]
  }

  if {$name!="A1" && $name!="A2"} {
    set wms($name,RadPw) [expr {($wms($name,RWI) - $x - $wms($name,RH))/($wms($name,RC) - $wms($name,RH))}]
    set wms($name,RadPt) [expr {($wms($name,RTI) - $x - $wms($name,RH))/($wms($name,RC) - $wms($name,RH))}]
  }

  set ctime [clock seconds]
  set time [clock format $ctime -format "%H:%M:%S"]

  set log [open $wms(data_path)/$wms(dae)/$wms(mn)/${name}/${name}_swms.txt "a"]

  foreach join {1 0 2} type {Iсв1 Iразв Iсв2} {
    if {!$join || ($join==1 && $wms($name,Io1)) || ($join==2 && $wms($name,Io2))} {
      set lst {Ref Bcur}
      lappend lst $type
      foreach item $lst {
        puts -nonewline $log $time

        puts -nonewline $log " [format "%03d" $n]"
        puts -nonewline $log "[format "%2d"   $i]"
        puts -nonewline $log "[format "%7.2f" $x]"
        puts -nonewline $log "[format "%7.2f" $y]"
        if {$name!="A1" && $name!="A2"} {
          puts -nonewline $log "[format "%8.4f"  $wms($name,RadPw)]"
          puts -nonewline $log "[format "%8.4f"  $wms($name,RadPt)]"
        }
        puts -nonewline $log "[format "%7.3f" $dens]"
        puts -nonewline $log "[format "%5d"   $join]"
        puts -nonewline $log "[format "%7s"   $item]"

        if {![info exists wms($name,temp,$n)]} {set wms($name,temp,$n) 0}

        puts -nonewline $log "[format "%7.2f" $wms($name,temp,$n)]"
        
        switch $item {
          Bcur    {
            foreach lamda $wms($name,swms,lamda) {
              puts -nonewline $log "[format "%8d" 0]"
            }
          }
          Ref     {
            foreach lamda $wms($name,swms,lamda) {
              puts -nonewline $log "[format "%8d" 1]"
            }
          }
          default {
            if {$join && $wms($name,new_meth) && $wms($name,tr,current)>=$wms($name,coord_in_tube)} {

              foreach meas $wms($name,swms,Ijn,$join) {
                puts -nonewline $log "[format "%8.1f" $meas]"
              }
            } elseif {![info exists wms($name,swms,Imeas,$n,$join)]} {
              foreach lamda $wms($name,swms,lamda) {
                puts -nonewline $log "[format "%8d" 1]"
              }
            } else {
              foreach meas $wms($name,swms,Imeas,$n,$join) {
                if {$wms(active)} {
                  puts -nonewline $log "[format "%8d" $meas]"
                } else {
                  puts -nonewline $log "[format "%8.1f" $meas]"
                }
              }
              if {$join && $wms($name,new_meth) && $wms($name,tr,current)<$wms($name,coord_in_tube)} {
                set wms($name,swms,Ijn,$join) $wms($name,swms,Imeas,$n,$join)
              }
            }
          }
        }
        puts $log ""
      }
    }
  }
  close $log
}