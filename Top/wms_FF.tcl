proc SaveCoef {name} {
global wms

  catch [file mkdir ./Data/Config/$name/]
  if {$wms($name,active)} {

    set log [open "./Data/Config/Coef_$wms($name,type).Log" "a"]

    puts -nonewline $log [format "%8s" Date]
    puts -nonewline $log [format "%9s" time]

    puts -nonewline $log [format "%4s" $name]
    puts -nonewline $log [format "%7s" $wms($name,type)]
    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log [format "%8s" $lamda]
    }

    puts $log ""

    puts -nonewline $log [clock format [clock seconds] -format "%y-%m-%d"]
    puts -nonewline $log [format "%1s" " "]
    puts -nonewline $log [clock format [clock seconds] -format "%H:%M:%S"]

    puts -nonewline $log [format "%4s" $name]
    puts -nonewline $log [format "%7s" $wms($name,type)]

    switch $wms($name,type) {

      "swms" {

        set of  [open "./Data/Config/$name/Coef_swms_$name.DAT" "w"]

        foreach lamda $wms($name,swms,lamda) {

          puts -nonewline $of [format "%8s" $lamda]
        }
        puts $of ""
        foreach lamda $wms($name,swms,lamda) {

          if {![info exists wms($name,coef,$lamda)]} {

            set wms($name,coef,$lamda) 1
          }
          puts -nonewline $log [format "%8.4f" $wms($name,coef,$lamda)]
          puts -nonewline $of [format "%8.4f" $wms($name,coef,$lamda)]
        }
        close $of
      }
    }
    puts $log ""
    close $log
  }
}

proc SaveWMSFile {name n rep} {
global wms

  if {!$wms($name,head_file)} {FillHeadSWMS $name}
  SaveFileSWMS $name $n $rep
}

proc SaveProp {} {
global wms meas

  set of [open $wms(DATAPATH)/Config/[info hostname]_prop.ini "w"]
  
  puts $of "wms(lamda,old,red) $wms(lamda,old,red)"
  puts $of "wms(lamda,old,blu) $wms(lamda,old,blu)"
  puts $of "wms(repeat) $wms(repeat)"
  puts $of "wms(tolerance) $wms(tolerance)"
  puts $of "wms(sensetivity) $wms(sensetivity)"
  puts $of "wms(calibr) $wms(calibr)"
  puts $of "wms(avermeas) $wms(avermeas)"
  puts $of "wms(COMPATH) $wms(COMPATH)"
  puts $of "wms(DATAPATH) $wms(DATAPATH)"
  puts $of "wms(zndjntctr) $wms(zndjntctr)"
  puts $of "wms(temp) $wms(temp)"
  puts $of "wms(sm) $wms(sm)"
  puts $of "wms(adr_tt) $wms(adr_tt)"

  foreach name {S01 S02} {

    puts $of ""
    puts $of "# $name"
    puts $of ""

    puts $of "wms($name,adr,moxa)  $wms($name,adr,moxa)"
    puts $of "wms($name,port,swms) $wms($name,port,swms)"
    puts $of "wms($name,port,adam) $wms($name,port,adam)"
    puts $of "wms($name,adr,adam)  $wms($name,adr,adam)"
    puts $of "wms($name,swms,IntTime) $wms($name,swms,IntTime)"

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC Y_cntr Io1 Io2} {
      if {![info exists wms($name,$item)]} {set wms($name,$item) 0}
      puts $of "wms($name,$item) $wms($name,$item)"
    }

    puts $of "wms($name,type) $wms($name,type)"

#    puts $of "wms($name,conf,adr) $wms($name,conf,adr)"

    foreach item {blu red} {

      puts $of "wms($name,2w,$item) $wms($name,2w,$item)"
    }
  }
  close $of
}

proc SavePropLog {} {
global wms meas

  set ctime [clock format [clock seconds] -format "%H:%M:%S"]
  set date [clock format [clock seconds] -format "%y_%m_%d"]

  set of [open [info hostname]_prop.log "a"]

  puts $of "${date} $ctime"

  puts $of ""

  puts $of "wms(lamda,old,red) $wms(lamda,old,red)"
  puts $of "wms(lamda,old,blu) $wms(lamda,old,blu)"
  puts $of "wms(repeat) $wms(repeat)"
  puts $of "wms(tolerance) $wms(tolerance)"
  puts $of "wms(sensetivity) $wms(sensetivity)"
  puts $of "wms(calibr) $wms(calibr)"
  puts $of "wms(avermeas) $wms(avermeas)"
  puts $of "wms(COMPATH) $wms(COMPATH)"
  puts $of "wms(DATAPATH) $wms(DATAPATH)"
  puts $of "wms(zndjntctr) $wms(zndjntctr)"
  puts $of "wms(temp) $wms(temp)"
  puts $of "wms(sm) $wms(sm)"

  foreach name {S01 S02} {
    set nmb 1
    lappend str($nmb) "_________________________________"
    lappend str($nmb) "_"
    incr nmb
    lappend str($nmb) [format "%33s" $name]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) "_________________________________"
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,adr,moxa)"]
    lappend str($nmb) [format "%10s" "$wms($name,adr,moxa)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,port,swms)"]
    lappend str($nmb) [format "%10s" "$wms($name,port,swms)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,port,adam)"]
    lappend str($nmb) [format "%10s" "$wms($name,port,adam)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,adr,adam)"]
    lappend str($nmb) [format "%10s" "$wms($name,adr,adam)"]
    lappend str($nmb) "|"
    incr nmb

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC Io1 Io2} {

      if {[info exists wms($name,$item)]} {
        lappend str($nmb) [format "%-22s" "wms($name,$item)"]
        lappend str($nmb) [format "%10s" "$wms($name,$item)"]
        lappend str($nmb) "|"
        incr nmb
      }
    }
    lappend str($nmb) [format "%-22s" "wms($name,type)"]
    lappend str($nmb) [format "%10s" "$wms($name,type)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,conf,adr)"]
    lappend str($nmb) [format "%10s" "$wms($name,conf,adr)"]
    lappend str($nmb) "|"
    incr nmb

    foreach item [concat $wms(colorlist) ref] {

      lappend str($nmb) [format "%-22s" "wms($name,conf,I_$item)"]
      lappend str($nmb) [format "%10s" "$wms($name,conf,I_$item)"]
      lappend str($nmb) "|"
      incr nmb
      lappend str($nmb) [format "%-22s" "wms($name,conf,U_$item)"]
      lappend str($nmb) [format "%10s" "$wms($name,conf,U_$item)"]
      lappend str($nmb) "|"
      incr nmb
    }

    foreach item $wms(colorlist) {

      lappend str($nmb) [format "%-22s" "wms($name,lamda,$item)"]
      lappend str($nmb) [format "%10s" "$wms($name,lamda,$item)"]
      lappend str($nmb) "|"
      incr nmb
      lappend str($nmb) [format "%-22s" "meas($name,$item)"]
      lappend str($nmb) [format "%10s" "$meas($name,$item)"]
      lappend str($nmb) "|"
      incr nmb
    }
    foreach item {blu red} {

      lappend str($nmb) [format "%-22s" "wms($name,2w,$item)"]
      lappend str($nmb) [format "%10s" "$wms($name,2w,$item)"]
      lappend str($nmb) "|"
      incr nmb
    }
    lappend str($nmb) "_________________________________"
    lappend str($nmb) "|"
    incr nmb
  }
  for {set i 1} {$i<$nmb} {incr i} {
  
    puts $of [join $str($i)]
  }
  puts $of ""
  close $of
}

proc FormRWVFile {pfn} {
global wms mtbl${pfn} row cb

  set name S$pfn

  file copy -force "./Data/Config/S$pfn/RWV_${pfn}.DAT" "./Data/Config/S$pfn/RWV_${pfn}.BAK"

  set of [open "./Data/Config/S$pfn/RWV_${pfn}.DAT" "w"]

  set mt "mtbl$pfn"
  for {set i 0} {$i<$row($name)} {incr i} {

    if {[info exist ${mt}($i,1)]} {

      set trav [format "%3.0f" [set ${mt}($i,1)]]
    } else {

      if {$i==0} {

        set trav [format "%3.0f" [set ${mt}([expr {$i+1}],1)]]
      } else {

        set trav [format "%3.0f" [set ${mt}([expr {$i-1}],1)]]
      }
    }

    if {[info exist ${mt}($i,2)]} {

      set ang [format "%3.0f" [set ${mt}($i,2)]]
    } else {

      if {$i==0} {

        set ang [format "%3.0f" [set ${mt}([expr {$i+1}],2)]]
      } else {

        set ang [format "%3.0f" [set ${mt}([expr {$i-1}],2)]]
      }
    }

    set dens [format "%5.3f" [set ${mt}($i,3)]]
    set wet $wms($name,wet,[expr $i+1])

    puts $of "$trav $ang $dens $wet"
  }
  close $of

  set wms(points) 0

  ReadRWV $name
}