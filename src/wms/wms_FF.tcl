proc SaveCoef {name man} {
global wms

  catch [file mkdir $wms(conf_path)/$name/]
  if {$wms($name,active)} {

    set log [open $wms(log_path)/coef_$wms($name,type).log "a"]

    puts -nonewline $log [format "%8s" Date]
    puts -nonewline $log [format "%9s" time]

    puts -nonewline $log [format "%4s" $name]
    puts -nonewline $log [format "%7s" $wms($name,type)]
    puts -nonewline $log [format "%7s" lamda]
    foreach lamda $wms($name,swms,lamda) {

      puts -nonewline $log [format "%8s" $lamda]
    }

    puts $log ""

    if {!$man} {
      switch $wms($name,type) {

        "swms" {
          foreach join {1 0} type {Iñ Ið} {
            puts -nonewline $log [clock format [clock seconds] -format "%y-%m-%d"]
            puts -nonewline $log [format "%1s" " "]
            puts -nonewline $log [clock format [clock seconds] -format "%H:%M:%S"]

            puts -nonewline $log [format "%4s" $name]
            puts -nonewline $log [format "%7s" $wms($name,type)]
            puts -nonewline $log [format "%7s" $type]

            foreach item $wms($name,swms,Imeas,k,$join) {

              if {!$wms(active)} {
                puts -nonewline $log [format "%8.1f" $item]
              } else {
                puts -nonewline $log [format "%8d" $item]
              }
            }
            puts $log ""
          }
        }
      }
    }
    puts -nonewline $log [clock format [clock seconds] -format "%y-%m-%d"]
    puts -nonewline $log [format "%1s" " "]
    puts -nonewline $log [clock format [clock seconds] -format "%H:%M:%S"]

    puts -nonewline $log [format "%4s" $name]
    puts -nonewline $log [format "%7s" $wms($name,type)]
    puts -nonewline $log [format "%7s" coef_k]

    switch $wms($name,type) {

      "swms" {

        set of  [open $wms(conf_path)/$name/coef_swms_$name.dat "w"]

        foreach lamda $wms($name,swms,lamda) {

          puts -nonewline $of [format "%8s" $lamda]
        }
        puts $of ""
        foreach lamda $wms($name,swms,lamda) {

          if {![info exists wms($name,coef,$lamda)]} {

            set wms($name,coef,$lamda) 1.
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

  set of [open $wms(conf_path)/$wms(hostname)_prop.ini "w"]
  
  puts $of "wms(lamda,old,red) $wms(lamda,old,red)"
  puts $of "wms(lamda,old,blu) $wms(lamda,old,blu)"
  puts $of "wms(repeat) $wms(repeat)"
  puts $of "wms(tolerance) $wms(tolerance)"
  puts $of "wms(sensetivity) $wms(sensetivity)"
  puts $of "wms(calibr) $wms(calibr)"
  puts $of "wms(avermeas) $wms(avermeas)"
  puts $of "wms(COMPATH) $wms(COMPATH)"
  puts $of "wms(data_path) $wms(data_path)"
  puts $of "wms(zndjntctr) $wms(zndjntctr)"
  puts $of "wms(temp) $wms(temp)"
  puts $of "wms(sm) $wms(sm)"
  puts $of "wms(adr_tt) $wms(adr_tt)"
  puts $of "wms(active) $wms(active)"
  puts $of "wms(calculate) $wms(calculate)"

  foreach name {S01 S02} {

    puts $of ""
    puts $of "# $name"
    puts $of ""

    puts $of "wms($name,new_meth)  $wms($name,new_meth)"
    puts $of "wms($name,coord_in_tube)  $wms($name,coord_in_tube)"
    puts $of "wms($name,meth)  $wms($name,meth)"
    puts $of "wms($name,adr,moxa)  $wms($name,adr,moxa)"
    puts $of "wms($name,port,swms) $wms($name,port,swms)"
    puts $of "wms($name,port,adam) $wms($name,port,adam)"
    puts $of "wms($name,adr,adam)  $wms($name,adr,adam)"
    puts $of "wms($name,swms,IntTime) $wms($name,swms,IntTime)"

    puts $of "wms($name,corIo) $wms($name,corIo)"
    puts $of "wms($name,l,uv) $wms($name,l,uv)"
    puts $of "wms($name,l,ir) $wms($name,l,ir)"
    puts $of "wms($name,npoints) $wms($name,npoints)"

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC Y_cntr Io1 Io2} {
      if {![info exists wms($name,$item)]} {set wms($name,$item) 0}
      puts $of "wms($name,$item) $wms($name,$item)"
    }

    puts $of "wms($name,type) $wms($name,type)"

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

  set of [open $wms(log_path)/$wms(hostname)_prop.log "a"]

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
  puts $of "wms(data_path) $wms(data_path)"
  puts $of "wms(zndjntctr) $wms(zndjntctr)"
  puts $of "wms(temp) $wms(temp)"
  puts $of "wms(sm) $wms(sm)"

  foreach name {S01 S02} {
    set nmb 1
    lappend str($nmb) "_______________________________________"
    lappend str($nmb) "_"
    incr nmb
    lappend str($nmb) [format "%39s" $name]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) "_______________________________________"
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,adr,moxa)"]
    lappend str($nmb) [format "%16s" "$wms($name,adr,moxa)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,port,swms)"]
    lappend str($nmb) [format "%16s" "$wms($name,port,swms)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,port,adam)"]
    lappend str($nmb) [format "%16s" "$wms($name,port,adam)"]
    lappend str($nmb) "|"
    incr nmb
    lappend str($nmb) [format "%-22s" "wms($name,adr,adam)"]
    lappend str($nmb) [format "%16s" "$wms($name,adr,adam)"]
    lappend str($nmb) "|"
    incr nmb

    foreach item {L RWI RTI RC RH ALFAI TEMPA TEMPB TEMPC coord_in_tube meth new_meth Io1 Io2} {

      if {[info exists wms($name,$item)]} {
        lappend str($nmb) [format "%-22s" "wms($name,$item)"]
        lappend str($nmb) [format "%16s" "$wms($name,$item)"]
        lappend str($nmb) "|"
        incr nmb
      }
    }
    lappend str($nmb) [format "%-22s" "wms($name,type)"]
    lappend str($nmb) [format "%16s" "$wms($name,type)"]
    lappend str($nmb) "|"
    incr nmb

    foreach item {blu red} {

      lappend str($nmb) [format "%-22s" "wms($name,2w,$item)"]
      lappend str($nmb) [format "%16s" "$wms($name,2w,$item)"]
      lappend str($nmb) "|"
      incr nmb
    }
    lappend str($nmb) "_______________________________________"
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

  catch [file mkdir $wms(conf_path)/S$pfn]

  if { [file exists $wms(conf_path)/S$pfn/RWV_${pfn}.dat]} {

    file copy -force $wms(conf_path)/S$pfn/RWV_${pfn}.dat $wms(conf_path)/S$pfn/RWV_${pfn}.bak
  }

  set of [open $wms(conf_path)/S$pfn/RWV_${pfn}.dat "w"]

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